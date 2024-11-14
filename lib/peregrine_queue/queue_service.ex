defmodule PeregrineQueue.QueueService.Reflection do
  use GrpcReflection.Server, version: :v1alpha, services: [Queue.QueueService.Service]
end
defmodule PeregrineQueue.QueueService do
  use GRPC.Server, service: Queue.QueueService.Service
  alias PeregrineQueue.WorkerRegistry
  alias PeregrineQueue.JobDataService

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
    queue_name: queue,
    data: data,
    worker_id: worker_id,
    job_id: job_id,
    status: status
  }, _) do
    #get job data
    #update job data

    IO.puts("WORK REPORT")
    job_data = JobDataService.get_job_data_by_oban_id(job_id)
    |> IO.inspect

    JobDataService.update_job_data(job_data, %{status: status})

    %Queue.WorkReportResponse{status: "success"}
  end

  def pull_work(%Queue.PullWorkRequest{
    queue_name: queue
  }, _) do
    IO.puts("PULL WORK")
    {job_data, job_count} = JobDataService.get_next_job_data(queue)
    |> IO.inspect

    if job_data == nil do
      %Queue.PullWorkResponse{job_id: "", data: "", queue_name: ""}
    else
      %Queue.PullWorkResponse{
        job_id: job_data.oban_id,
        data: job_data.payload,
        queue_name: job_data.queue
      }
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
    WorkerRegistry.register_heartbeat(worker_id)

    %Queue.WorkerHeartbeatResponse{status: "success", message: "Heartbeat registered"}
  end

end
