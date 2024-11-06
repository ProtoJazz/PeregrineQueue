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

  # def register_heartbeat(worker_id) do
  #   :ets.insert(@worker_registry, {worker_id, %{last_heartbeat: System.monotonic_time()}})
  # end

  # # Check for timed-out workers and remove them
  # def remove_stale_workers(timeout \\ 30_000) do
  #   current_time = System.monotonic_time()

  #   :ets.tab2list(@worker_registry)
  #   |> Enum.each(fn {worker_id, %{last_heartbeat: last_heartbeat}} ->
  #     if current_time - last_heartbeat > timeout do
  #       :ets.delete(@worker_registry, worker_id)
  #       IO.puts("Removed stale worker #{worker_id}")
  #     end
  #   end)
  # end
end
