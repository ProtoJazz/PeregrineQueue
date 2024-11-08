use tonic::transport::Channel;
use queue::queue_service_client::QueueServiceClient;
use crate::queue::WorkerHeartbeatRequest;
use queue::RegisterWorkerRequest;
use tokio::time::Duration;
use tokio::time::sleep;

pub mod queue {
    tonic::include_proto!("queue"); // This assumes your proto package is "queue"
}

async fn send_heartbeat(client: &mut QueueServiceClient<Channel>, worker_id: String) -> Result<(), Box<dyn std::error::Error>> {
    loop {
        let request = tonic::Request::new(WorkerHeartbeatRequest {
            worker_id: worker_id.clone(),
        });

        let response = client.worker_heart_beat(request).await?;
        println!("Heartbeat Response: {:?}", response.get_ref());

        // Wait for 30 seconds before the next heartbeat
        sleep(Duration::from_secs(20)).await;
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Step 1: Connect to the server
    let mut client = QueueServiceClient::connect("http://localhost:50051").await?;

    // Step 2: Create the request with worker details
    let request = tonic::Request::new(RegisterWorkerRequest {
        queue_name: "my_queue".to_string(),
        worker_id: "worker_1".to_string(),
        worker_address: "localhost:50052".to_string(),
    });

    // Step 3: Call the RegisterWorker RPC
    let response = client.register_worker(request).await?;

    // Step 4: Process the response
    println!("Register Worker Response: {:?}", response.get_ref());

    send_heartbeat(&mut client, "worker_1".to_string()).await?;

    Ok(())
}

