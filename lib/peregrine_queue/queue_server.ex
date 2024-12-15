defmodule PeregrineQueue.QueueServer.Reflection do
  use GrpcReflection.Server, version: :v1alpha, services: [Queue.QueueService.Service]
end
defmodule PeregrineQueue.QueueServer do
  use GRPC.Server, service: Queue.QueueService.Service
  alias PeregrineQueue.WorkerRegistry
  alias PeregrineQueue.JobDataService
  alias PeregrineQueue.JobRateLimiter

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

  def work_report(%Queue.WorkReportRequest{
    job_id: job_id,
    status: status
  }, _) do
    job_data = JobDataService.get_job_data_by_job_data_id(job_id)
    |> IO.inspect

    JobDataService.update_job_data(job_data, %{status: status})

    %Queue.WorkReportResponse{status: "success"}
  end

  def pull_work(%Queue.PullWorkRequest{
    queue_name: queue_name
  }, _) do
    config = Application.get_env(:peregrine_queue, PeregrineQueue, [])
    pull_queues = Keyword.get(config, :pull_queues, [])
    queue = Enum.find(pull_queues, fn queue -> queue.name == queue_name end)
      {job_data, job_count} = JobDataService.get_next_job_data(queue_name)
      |> IO.inspect

      IO.inspect(queue)

      if job_data == nil or job_count >= queue.concurrency do
        IO.puts("Job data is nil or job count is greater than or equal to queue concurrency")
        %Queue.PullWorkResponse{job_id: -1, data: "", queue_name: ""}
      else
        case JobRateLimiter.can_execute?(queue_name) do
          :allowed ->
            job_data
              |> PeregrineQueue.JobData.changeset(%{status: :active})
              |> PeregrineQueue.Repo.update!()

              %Queue.PullWorkResponse{
                job_id: job_data.id,
                data: job_data.payload,
                queue_name: job_data.queue_name
              }
          :denied ->
            IO.puts("Rate limit exceeded")
            %Queue.PullWorkResponse{job_id: -1, data: "", queue_name: ""}
      end

    end
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
    IO.puts("HEARTBEAT")
    WorkerRegistry.register_heartbeat(worker_id)

    is_worker_registered = WorkerRegistry.is_worker_registered(worker_id)
    if(is_worker_registered) do
      %Queue.WorkerHeartbeatResponse{status: "success", message: "Heartbeat registered"}
    else
      %Queue.WorkerHeartbeatResponse{status: "unregistered", message: "Heartbeat registered"}
    end
  end

  def get_queues() do
    config = Application.get_env(:peregrine_queue, PeregrineQueue, [])
    pull_queues = Keyword.get(config, :pull_queues, [])
    push_queues = Keyword.get(config, :push_queues, [])
    pull_queues ++ push_queues
  end



end
