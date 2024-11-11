use crate::queue::WorkerHeartbeatRequest;
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

#[derive(Debug, Default)]
pub struct MyQueueService;

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

    async fn dispatch_work(
        &self,
        request: Request<DispatchWorkRequest>,
    ) -> Result<Response<DispatchWorkResponse>, Status> {
        let req = request.into_inner();
        println!("Received dispatch_work request for job_id: {}", req.job_id);

        // Return a dummy response
        let reply = DispatchWorkResponse {
            status: "complete".to_string(),
            worker_id: "worker_1".to_string(),
            worker_address: "localhost:50052".to_string(),
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
    tokio::spawn(async {
        let addr = "127.0.0.1:50052".parse().unwrap();
        let queue_service = MyQueueService::default();

        println!("QueueService server listening on {}", addr);

        Server::builder()
            .add_service(QueueServiceServer::new(queue_service))
            .serve(addr)
            .await
            .unwrap();
    });

    let mut client = QueueServiceClient::connect("http://localhost:50051").await?;

    let request = tonic::Request::new(RegisterWorkerRequest {
        queue_name: "data_sync".to_string(),
        worker_id: "worker_1".to_string(),
        worker_address: "localhost:50052".to_string(),
    });

    let response = client.register_worker(request).await?;

    println!("Register Worker Response: {:?}", response.get_ref());

    send_heartbeat(&mut client, "worker_1".to_string()).await?;

    Ok(())
}
