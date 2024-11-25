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
use tracing::info;
use tonic_reflection::server::Builder;
use rand::Rng;
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
    /// Demo mode (optional, defaults to false)
    #[arg(long, default_value_t = false)]
    demo_mode: bool,
}

#[derive(Debug, Clone)]
struct ServiceConfig {
    worker_id: String,
    worker_address: String,
    queue_name: String,
    demo_mode: bool,
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
    config: Config,
) -> Result<(), Box<dyn std::error::Error>> {
    loop {
        let request = tonic::Request::new(WorkerHeartbeatRequest {
            worker_id: config.worker_id.clone(),
        });

        let response = client.worker_heart_beat(request).await?;
        println!("Heartbeat Response: {:?}", response.get_ref());
        if(response.get_ref().status == "unregistered") {
            let request = tonic::Request::new(RegisterWorkerRequest {
                queue_name: config.queue_name.clone(),
                worker_id: config.worker_id.clone(),
                worker_address: config.worker_address.clone(),
            });

            let response = client.register_worker(request).await?;
        }

        // Wait for 30 seconds before the next heartbeat
        sleep(Duration::from_secs(360)).await;
    }
}

async fn get_internal_ipv6() -> Option<String> {
    // Get the IP directly from Fly.io environment variable
    if let Ok(ip) = std::env::var("FLY_PRIVATE_IP") {
        println!("Found Fly.io private IP: {}", ip);
        return Some(ip);
    }
    
    println!("FLY_PRIVATE_IP not found in environment");
    None
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
        println!("\n=== DISPATCH WORK REQUEST RECEIVED ===");
        println!("Remote address: {:?}", request.remote_addr());
        println!("Request extensions: {:?}", request.extensions());
        println!("Raw request: {:?}", request);
        println!("Full metadata: {:?}", request.metadata());
        
        let req = request.into_inner();
        println!("\n=== REQUEST DETAILS ===");
        println!("Job ID: {}", req.job_id);
        println!("Queue Name: {}", req.queue_name);
        println!("Data: {}", req.data);
        println!("Full request struct: {:?}", req);
        
        
        let mut status = "complete".to_string(); // Default status

        if self.config.demo_mode {
            println!("Demo mode enabled, sleeping for 5 seconds before responding...");
            sleep(Duration::from_secs(5)).await;
    
            // Generate a random 50/50 chance only in demo mode
            let mut rng = rand::thread_rng();
            if rng.gen_bool(0.5) {
                status = "failed".to_string();
            }
        }
    

        let reply = DispatchWorkResponse {
            status: status,
            worker_id: self.config.worker_id.to_string(),
            worker_address: self.config.worker_address.to_string(),
        };
    
        println!("\n=== SENDING RESPONSE ===");
        println!("Response details: {:?}", reply);
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

async fn test_local_server(address: String) -> Result<(), Box<dyn std::error::Error>> {
    println!("\n=== Testing local server ===");
    println!("Attempting to connect to: {}", address);
    
    let uri = format!("http://{}", address).parse()?;
    
    match Channel::builder(uri)
        .connect_timeout(Duration::from_secs(5))
        .tcp_nodelay(true)
        .connect()
        .await 
    {
        Ok(channel) => {
            println!("Successfully connected to local server");
            let mut client = QueueServiceClient::new(channel);
            
            let request = tonic::Request::new(DispatchWorkRequest {
                job_id: 12345,  // Changed to i32
                queue_name: "test-queue".to_string(),
                data: "test data".to_string(),
            });
            
            println!("Sending test dispatch request...");
            match client.dispatch_work(request).await {
                Ok(response) => {
                    println!("Got response: {:?}", response.get_ref());
                    Ok(())
                }
                Err(e) => {
                    println!("Dispatch failed: {:?}", e);
                    Err(Box::new(e))
                }
            }
        }
        Err(e) => {
            println!("Connection failed: {:?}", e);
            Err(Box::new(e))
        }
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt::init();
    let config = Config::parse();

    let port = config.worker_address.split(':').last().unwrap_or("50053");
    
    let bind_addr = format!("[::]:{}", port);

    let ipv6_address = match get_internal_ipv6().await {
        Some(ip) => {
            println!("Using Fly.io private IP: {}", ip);
            format!("[{}]:{}", ip, port)
        },
        None => {
            println!("Warning: Could not find Fly.io private IP, falling back to provided address");
            config.worker_address.clone()
        }
    };
    


    let service_config = ServiceConfig {
        worker_id: config.worker_id.clone(),
        worker_address: ipv6_address.clone(),
        queue_name: config.queue_name.clone(),
        demo_mode: config.demo_mode
    };

    let (tx, rx) = tokio::sync::oneshot::channel();

    // Spawn the server task
    let server_config = service_config.clone();
    let bind_addr_clone = bind_addr.clone();
    tokio::spawn(async move {
        let queue_service = MyQueueService::new(server_config);
        
        let addr = bind_addr_clone.parse().unwrap();
        println!("=== SERVER STARTUP ===");
        println!("QueueService server listening on {}", addr);
        println!("Server configuration: {:?}", queue_service);
        
        // Signal that we're about to start the server
        tx.send(()).unwrap();

        println!("Starting server with enhanced logging...");

        let reflection_service = Builder::configure()
        .register_encoded_file_descriptor_set(include_bytes!("../proto_descriptor.bin"))
        .build()
        .unwrap();
        
        match Server::builder()
                .trace_fn(|_| tracing::info_span!("tonic_server"))
                // Remove accept_http1 since gRPC requires HTTP/2
                .tcp_keepalive(Some(Duration::from_secs(60)))
                .tcp_nodelay(true)
                .max_concurrent_streams(Some(100))  // Match client settings
                .max_frame_size(Some(16384))       // Match client settings
                .initial_connection_window_size(65535) // Match client settings
                .initial_stream_window_size(65535)    // Match client settings
                .add_service(QueueServiceServer::new(queue_service))
                .add_service(reflection_service)
                .serve(addr)
            .await 
        {
            Ok(_) => println!("Server shutdown normally"),
            Err(e) => println!("Server error: {:?}", e),
        }
    });

    // Wait for server to start
    rx.await?;
    println!("Server process started");
    
    // Additional delay to ensure server is fully ready
    println!("Waiting for server to be fully ready...");
    tokio::time::sleep(Duration::from_secs(2)).await;

    println!("Connecting to queue server {}", config.queue_address);
    let mut client = connect_to_queue_server(config.queue_address.clone()).await?;
    println!("Connected to queue server");

    println!("Registering worker with queue server");
    println!("Worker ID: {}", config.worker_id);
    println!("Worker Address: {}", ipv6_address);
    println!("Queue Name: {}", config.queue_name);
    
    let request = tonic::Request::new(RegisterWorkerRequest {
        queue_name: config.queue_name.clone(),
        worker_id: config.worker_id.clone(),
        worker_address: config.worker_address.clone(),
    });

    let response = client.register_worker(request).await?;
    println!("Register Worker Response: {:?}", response.get_ref());
   
    println!("Testing local server...");
    if let Err(e) = test_local_server(ipv6_address.clone()).await {
        println!("Local server test failed: {:?}", e);
    } else {
        println!("Local server test passed!");
    }

    // Start heartbeat
    send_heartbeat(&mut client, config).await?;
    
    Ok(())
}