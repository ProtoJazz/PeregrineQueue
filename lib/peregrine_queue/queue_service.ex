defmodule PeregrineQueue.QueueService.Reflection do
  use GrpcReflection.Server, version: :v1alpha, services: [Queue.QueueService.Service]
end
defmodule PeregrineQueue.QueueService do
  use GRPC.Server, service: Queue.QueueService.Service
  alias PeregrineQueue.WorkerRegistry

  def register_worker(
        %Queue.RegisterWorkerRequest{
          queue_name: queue,
          worker_id: id,
          worker_address: address
        },
        _
      ) do
    IO.puts("Registered worker #{id} for queue #{queue} at #{address}")

    WorkerRegistry.register_worker(queue, %{worker_id: id, worker_address: address})

    %Queue.RegisterWorkerResponse{status: "success", message: "Worker registered successfully"}
  end

  def get_workers_for_queue(%Queue.GetWorkersForQueueRequest{
    queue_name: queue
  }, _) do
    IO.puts("GET TO WORK")
    workers = WorkerRegistry.get_workers_for_queue(queue)
    |> IO.inspect
    |> Enum.map(fn worker_info ->
      %Queue.Worker{
        worker_id: worker_info.worker_id,
        worker_address: worker_info.worker_address
      }
    end)

    %Queue.GetWorkersForQueueResponse{workers: workers}
  end

  def get_workers_for_queue(queue_name) do
    WorkerRegistry.get_workers_for_queue(queue_name)
  end

  def worker_heart_beat(%Queue.WorkerHeartbeatRequest{
    worker_id: worker_id
  }, _) do
    WorkerRegistry.register_heartbeat(worker_id)

    %Queue.WorkerHeartbeatResponse{status: "success", message: "Heartbeat registered"}
  end

  def dispatch_work(job_id, queue_name, worker_address, data) do
    IO.puts("Dispatching work for job #{job_id} in queue #{queue_name}")
    {:ok, "Work dispatched"}
  end

end
