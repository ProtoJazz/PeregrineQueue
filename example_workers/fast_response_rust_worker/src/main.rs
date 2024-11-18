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

pub mod queue {
    tonic::include_proto!("queue");
}
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Config {
    /// Worker server address
    #[arg(long, default_value = "0.0.0.0:50053")]
    worker_server_address: String,
    /// Worker ID
    #[arg(long, default_value = "fast_running_rust_worker")]
    worker_id: String,

    /// Worker Address
    #[arg(long, default_value = "127.0.0.1:50053")]
    worker_address: String,

    /// Queue Address
    #[arg(long, default_value = "http://localhost:50051")]
    queue_address: String,

    /// Queue Name
    #[arg(long, default_value = "media_update")]
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

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = Config::parse();
    
    let worker_address_for_server = config.worker_server_address.clone();
    let worker_address_for_client = config.worker_address.clone();
    let queue_address = config.queue_address.clone();
    let service_config = ServiceConfig {
        worker_id: config.worker_id.clone(),
        worker_address: worker_address_for_server.clone(),
        queue_name: config.queue_name.clone(),
    };
    tokio::spawn(async move {
        let addr = worker_address_for_server.parse().unwrap();
       
        let queue_service = MyQueueService::new(service_config);

        
        println!("QueueService server listening on {}", addr);

        Server::builder()
            .add_service(QueueServiceServer::new(queue_service))
            .serve(addr)
            .await
            .unwrap();
    });
    println!("Connecting to queue server {}", queue_address.clone());
    let mut client = QueueServiceClient::connect(queue_address.clone()).await?;
    println!("Connected to queue server");
    println!("Registering worker with queue server");
    println!("Worker ID: {}", config.worker_id);
    println!("Worker Address: {}", worker_address_for_client);
    println!("Queue Name: {}", config.queue_name);
    println!("Queue Address: {}", queue_address);
    let request = tonic::Request::new(RegisterWorkerRequest {
        queue_name: config.queue_name.to_string(),
        worker_id: config.worker_id.to_string(),
        worker_address: worker_address_for_client.clone().to_string(),
    });

    let response = client.register_worker(request).await?;

    println!("Register Worker Response: {:?}", response.get_ref());

    send_heartbeat(&mut client, config.worker_id.to_string()).await?;

    Ok(())
}
