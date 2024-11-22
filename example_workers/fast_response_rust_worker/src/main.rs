use crate::queue::WorkerHeartbeatRequest;
use clap::Parser;
use queue::queue_service_client::QueueServiceClient;
use queue::queue_service_server::{QueueService, QueueServiceServer};
use queue::{
    DispatchWorkRequest, DispatchWorkResponse, GetWorkersForQueueRequest,
    GetWorkersForQueueResponse, RegisterWorkerRequest, RegisterWorkerResponse,
    WorkerHeartbeatResponse,
};
use tokio::time::sleep;
use tokio::time::Duration;
use tonic::{transport::Channel, transport::Server, Request, Response, Status};
use std::net::ToSocketAddrs;
use tonic::transport::Uri;

pub mod queue {
    tonic::include_proto!("queue");
}
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Config {
    /// Worker ID
    #[arg(long)]
    worker_id: String,
    /// Worker Address
    #[arg(long)]
    worker_address: String,
    /// Queue Address
    #[arg(long)]
    queue_address: String,
    /// Queue Name
    #[arg(long)]
    queue_name: String,
}

#[derive(Debug, Clone)]
struct ServiceConfig {
    worker_id: String,
    worker_address: String,
    queue_name: String,
}

#[derive(Debug)]
pub struct MyQueueService {
    config: ServiceConfig,
}

impl MyQueueService {
    pub fn new(config: ServiceConfig) -> Self {
        Self { config }
    }
}

async fn send_heartbeat(
    client: &mut QueueServiceClient<Channel>,
    worker_id: String,
) -> Result<(), Box<dyn std::error::Error>> {
    loop {
        let request = tonic::Request::new(WorkerHeartbeatRequest {
            worker_id: worker_id.clone(),
        });

        let response = client.worker_heart_beat(request).await?;
        println!("Heartbeat Response: {:?}", response.get_ref());

        // Wait for 30 seconds before the next heartbeat
        sleep(Duration::from_secs(30)).await;
    }
}

async fn get_ipv6_address(hostname: &str) -> Option<String> {
    if let Ok(addrs) = hostname.to_socket_addrs() {
        for addr in addrs {
            if addr.is_ipv6() {
                return Some(format!("[{}]:{}", addr.ip(), addr.port()));
            }
        }
    }
    None
}
#[tonic::async_trait]
impl QueueService for MyQueueService {
    async fn register_worker(
        &self,
        _: Request<RegisterWorkerRequest>,
    ) -> Result<Response<RegisterWorkerResponse>, Status> {
        Err(Status::unimplemented("register_worker is not implemented"))
    }

    async fn worker_heart_beat(
        &self,
        _: Request<WorkerHeartbeatRequest>,
    ) -> Result<Response<WorkerHeartbeatResponse>, Status> {
        Err(Status::unimplemented(
            "worker_heart_beat is not implemented",
        ))
    }

    async fn get_workers_for_queue(
        &self,
        _: Request<GetWorkersForQueueRequest>,
    ) -> Result<Response<GetWorkersForQueueResponse>, Status> {
        Err(Status::unimplemented(
            "get_workers_for_queue is not implemented",
        ))
    }

    async fn pull_work(
        &self,
        _: Request<queue::PullWorkRequest>,
    ) -> Result<Response<queue::PullWorkResponse>, Status> {
        Err(Status::unimplemented("pull_work is not implemented"))
    }

    async fn work_report(
        &self,
        _: Request<queue::WorkReportRequest>,
    ) -> Result<Response<queue::WorkReportResponse>, Status> {
        Err(Status::unimplemented("work_report is not implemented"))
    }

    async fn dispatch_work(
        &self,
        request: Request<DispatchWorkRequest>,
    ) -> Result<Response<DispatchWorkResponse>, Status> {
        println!("Received dispatch_work request from: {:?}", request.remote_addr());
        let req = request.into_inner();
        println!("Received dispatch_work request for job_id: {}", req.job_id);

        // Return a dummy response
        let reply = DispatchWorkResponse {
            status: "complete".to_string(),
            worker_id: self.config.worker_id.to_string(),
            worker_address: self.config.worker_address.to_string(),
        };

        Ok(Response::new(reply))
    }
}
async fn connect_to_queue_server(queue_address: String) -> Result<QueueServiceClient<Channel>, Box<dyn std::error::Error>> {
    loop {
        let endpoint_uri = if queue_address.contains("://") {
            queue_address.clone()
        } else {
            format!("http://{}", queue_address)
        };
        
        println!("Attempting to connect to: {}", endpoint_uri);
        
        let uri = match endpoint_uri.parse::<Uri>() {
            Ok(uri) => uri,
            Err(e) => {
                println!("Failed to parse URI: {:?}", e);
                sleep(Duration::from_secs(5)).await;
                continue;
            }
        };

        match Channel::builder(uri)
            .connect_timeout(Duration::from_secs(5))
            .tcp_nodelay(true)
            .connect()
            .await
        {
            Ok(channel) => return Ok(QueueServiceClient::new(channel)),
            Err(err) => {
                println!(
                    "Failed to connect to queue server: {:?}. Retrying in 5 seconds...",
                    err
                );
                sleep(Duration::from_secs(5)).await;
            }
        }
    }
}


#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = Config::parse();

    // Extract the port for binding
    let port = config.worker_address.split(':').last().unwrap_or("50053");
    let bind_addr = format!("peregrinequeue-worker.internal:{}", port);

    // Use the original internal DNS name for registration
    let registration_address = config.worker_address.clone();

    let service_config = ServiceConfig {
        worker_id: config.worker_id.clone(),
        worker_address: registration_address.clone(),
        queue_name: config.queue_name.clone(),
    };

    // Spawn the server task
    let server_config = service_config.clone();
    tokio::spawn(async move {
        let queue_service = MyQueueService::new(server_config);
        
        let addr = bind_addr.parse().unwrap();
        println!("QueueService server listening on {}", addr);
        
        Server::builder()
            .add_service(QueueServiceServer::new(queue_service))
            .serve(addr)
            .await
            .unwrap();
    });

    println!("Connecting to queue server {}", config.queue_address);
    let mut client = connect_to_queue_server(config.queue_address.clone()).await?;
    println!("Connected to queue server");

    println!("Registering worker with queue server");
    println!("Worker ID: {}", config.worker_id);
    println!("Worker Address: {}", registration_address);
    println!("Queue Name: {}", config.queue_name);
    
    let request = tonic::Request::new(RegisterWorkerRequest {
        queue_name: config.queue_name,
        worker_id: config.worker_id.clone(),
        worker_address: registration_address,
    });

    let response = client.register_worker(request).await?;
    println!("Register Worker Response: {:?}", response.get_ref());

    // Start heartbeat
    send_heartbeat(&mut client, config.worker_id).await?;

    Ok(())
}