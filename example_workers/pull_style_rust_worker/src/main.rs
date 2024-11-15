use crate::queue::WorkerHeartbeatRequest;
use queue::queue_service_client::QueueServiceClient;
use queue::queue_service_server::{QueueService, QueueServiceServer};
use queue::{
    DispatchWorkRequest, DispatchWorkResponse, GetWorkersForQueueRequest,
    GetWorkersForQueueResponse, RegisterWorkerRequest, RegisterWorkerResponse,
    WorkerHeartbeatResponse, PullWorkRequest, WorkReportRequest, WorkReportResponse
};
use tokio::time::sleep;
use tokio::time::Duration;
use tonic::{transport::Channel, transport::Server, Request, Response, Status};
use rand::Rng;
pub mod queue {
    tonic::include_proto!("queue");
}

const WORKER_ID: &str = "pull_style_rust_worker";
const WORKER_ADDRESS: &str = "127.0.0.1:50054";
const QUEUE_ADDRESS: &str = "http://localhost:50051";
const QUEUE_NAME: &str = "web_scrapping";

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
            worker_id: WORKER_ID.to_string(),
            worker_address: WORKER_ADDRESS.to_string(),
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

async fn pull_work(
    client: &mut QueueServiceClient<Channel>,
    worker_id: String,
) -> Result<(), Box<dyn std::error::Error>> {
    loop {
        let request = tonic::Request::new(PullWorkRequest {
            queue_name: QUEUE_NAME.to_string(),
        });

        let response = client.pull_work(request).await?;
        println!("Pull Work Response: {:?}", response.get_ref());

        if(response.get_ref().job_id == -1){
            println!("No work available");
            sleep(Duration::from_secs(30)).await;
            continue;
        }
        let random_sleep = rand::thread_rng().gen_range(20..100);
        sleep(Duration::from_secs(random_sleep)).await;


        let work_report = tonic::Request::new(queue::WorkReportRequest {
            job_id: response.get_ref().job_id,
            worker_id: WORKER_ID.to_string(),
            status: "complete".to_string(),
            queue_name: QUEUE_NAME.to_string(),
            data: "{}".to_string(),
    
        });

        let response = client.work_report(work_report).await?;
        println!("Work Report Response: {:?}", response.get_ref());
    
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tokio::spawn(async {
        let addr = WORKER_ADDRESS.parse().unwrap();
        let queue_service = MyQueueService::default();

        println!("QueueService server listening on {}", addr);

        Server::builder()
            .add_service(QueueServiceServer::new(queue_service))
            .serve(addr)
            .await
            .unwrap();
    });

    let mut client = QueueServiceClient::connect(QUEUE_ADDRESS).await?;

    let request = tonic::Request::new(RegisterWorkerRequest {
        queue_name: QUEUE_NAME.to_string(),
        worker_id: WORKER_ID.to_string(),
        worker_address: WORKER_ADDRESS.to_string(),
    });

    let response = client.register_worker(request).await?;

    println!("Register Worker Response: {:?}", response.get_ref());

    //send_heartbeat(&mut client, WORKER_ID.to_string()).await?;
    pull_work(&mut client, WORKER_ID.to_string()).await?;

    Ok(())
}
