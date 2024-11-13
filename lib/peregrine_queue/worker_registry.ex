defmodule PeregrineQueue.WorkerRegistry do
  use GenServer
  require Logger

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

  def init(_) do
    :ets.new(@worker_registry, [:named_table, :public, :bag])
    schedule_worker_removal()
    {:ok, %{}}
  end

  defp schedule_worker_removal() do
    Logger.info("Scheduling worker removal")
    :timer.send_interval(60 * 1000, :begin_purge)
  end

  def remove_stale_workers(timeout \\ 5 * 60_000) do
    current_time = System.monotonic_time(:millisecond)

    :ets.tab2list(@worker_registry)
    |> Enum.each(fn
      {queue, %{last_heartbeat: last_heartbeat, worker_id: worker_id} = worker_info} when is_integer(last_heartbeat) ->
        if current_time - last_heartbeat > timeout do
          :ets.delete_object(@worker_registry, {queue, worker_info})
          Logger.info("Removed stale worker #{worker_id} from queue #{queue}")
        else
          Logger.info("Worker #{worker_id} in queue #{queue} is still active")
        end

      {queue, _} ->
        Logger.info("Worker in queue #{queue} does not have a valid last_heartbeat field")
    end)
  end

  def handle_info(:begin_purge, state) do
    remove_stale_workers()
    {:noreply, state}
  end

  def handle_call({:register_worker, queue, worker_info}, _from, state) do
    worker_info = Map.put(worker_info, :last_heartbeat, System.monotonic_time(:millisecond))
    :ets.insert(@worker_registry, {queue, worker_info})
    {:reply, :ok, state}
  end

  def handle_call({:get_workers_for_queue, queue}, _from, state) do
    workers = :ets.lookup(@worker_registry, queue) |> Enum.map(fn {_queue, info} -> info end)
    {:reply, workers, state}
  end

  def handle_cast({:register_heartbeat, worker_id}, state) do
    Logger.info("Processing heartbeat for worker_id: #{worker_id}")

    # Get current table contents
    current_entries = :ets.tab2list(@worker_registry)

    current_entries
    |> Enum.each(fn
      {queue, %{worker_id: ^worker_id} = worker_info} ->
        current_time = System.monotonic_time(:millisecond)
        :ets.delete_object(@worker_registry, {queue, worker_info})
        updated_worker_info = Map.put(worker_info, :last_heartbeat, current_time)
        :ets.insert(@worker_registry, {queue, updated_worker_info})

      _ ->
        {}
    end)

    {:noreply, state}
  end
end
