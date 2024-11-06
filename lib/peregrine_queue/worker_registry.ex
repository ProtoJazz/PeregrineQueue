defmodule PeregrineQueue.WorkerRegistry do
  use GenServer

  @worker_registry :worker_registry

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register_worker(queue, worker_info) do
    GenServer.call(__MODULE__, {:register_worker, queue, worker_info})
  end

  def get_workers_for_queue(queue) do
    GenServer.call(__MODULE__, {:get_workers_for_queue, queue})
  end

  def register_heartbeat(worker_id) do
    GenServer.cast(__MODULE__, {:register_heartbeat, worker_id})
  end

  def remove_stale_workers(timeout \\ 30_000) do
    GenServer.cast(__MODULE__, {:remove_stale_workers, timeout})
  end

  def init(_) do
    :ets.new(@worker_registry, [:named_table, :public, :bag])
    {:ok, %{}}
  end

  def handle_call({:register_worker, queue, worker_info}, _from, state) do
    :ets.insert(@worker_registry, {queue, worker_info})
    {:reply, :ok, state}
  end

  def handle_call({:get_workers_for_queue, queue}, _from, state) do
    workers = :ets.lookup(@worker_registry, queue) |> Enum.map(fn {_queue, info} -> info end)
    {:reply, workers, state}
  end

  def handle_cast({:register_heartbeat, worker_id}, state) do
    :ets.insert(@worker_registry, {worker_id, %{last_heartbeat: System.monotonic_time()}})
    {:noreply, state}
  end

  def handle_cast({:remove_stale_workers, timeout}, state) do
    current_time = System.monotonic_time()

    :ets.tab2list(@worker_registry)
    |> Enum.each(fn {worker_id, %{last_heartbeat: last_heartbeat}} ->
      if current_time - last_heartbeat > timeout do
        :ets.delete(@worker_registry, worker_id)
        IO.puts("Removed stale worker #{worker_id}")
      end
    end)

    {:noreply, state}
  end
end
