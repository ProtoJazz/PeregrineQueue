defmodule PeregrineQueue.JobRateLimiter do
  use GenServer
  @rate_limit 10   # Maximum jobs per minute
  @time_window 60_000  # Time window in milliseconds (60 seconds)

  def start_link(_) do
    :ets.new(:job_rate_limiter, [:named_table, :public, :set])
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def can_execute?(queue_name) do
    all_queues =
      Application.get_env(:peregrine_queue, PeregrineQueue, %{push_queues: [], pull_queues: []})
      |> (&(&1[:push_queues] ++ &1[:pull_queues])).()


    queue = Enum.find(all_queues, fn queue -> queue.name == queue_name end)
    rate_limit = queue.rate_limit || @rate_limit
    time_window = queue.rate_window || @time_window
    now = :erlang.system_time(:millisecond)

    executions = :ets.lookup(:job_rate_limiter, queue_name)
    |> case do
      [] -> []
      [{_, timestamps}] -> timestamps
    end

    recent_executions = Enum.filter(executions, fn timestamp -> now - timestamp < time_window end)

    if length(recent_executions) < rate_limit do
      :ets.insert(:job_rate_limiter, {queue_name, [now | recent_executions]})
      :allowed
    else
      :denied
    end
  end
end
