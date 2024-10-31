defmodule PeregrineQueue.QueueService do
  use GrpcReflection.Server, version: :v1alpha, services: [Queue.QueueService.Service]

  @worker_registry :worker_registry

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_) do
    :ets.new(@worker_registry, [:named_table, :public, :bag])
  end

  # Register a worker for a specific queue
  def register_worker(
        %Queue.RegisterWorkerRequest{
          queue_name: queue,
          worker_id: id,
          worker_address: address
        },
        _
      ) do
    IO.puts("Registered worker #{id} for queue #{queue} at #{address}")

    :ets.insert(@worker_registry, {queue, %{worker_id: id, address: address}})

    %Queue.RegisterWorkerResponse{status: "success", message: "Worker registered successfully"}
  end

  def register_worker(_, _) do
    %Queue.RegisterWorkerResponse{status: "failure", message: "Invalid request"}
  end

  def get_workers_for_queue(queue) do
    :ets.lookup(@worker_registry, queue)
    |> Enum.map(fn {_queue, worker_info} -> worker_info end)
  end

  def register_heartbeat(worker_id) do
    :ets.insert(@worker_registry, {worker_id, %{last_heartbeat: System.monotonic_time()}})
  end

  # Check for timed-out workers and remove them
  def remove_stale_workers(timeout \\ 30_000) do
    current_time = System.monotonic_time()

    :ets.tab2list(@worker_registry)
    |> Enum.each(fn {worker_id, %{last_heartbeat: last_heartbeat}} ->
      if current_time - last_heartbeat > timeout do
        :ets.delete(@worker_registry, worker_id)
        IO.puts("Removed stale worker #{worker_id}")
      end
    end)
  end
end
