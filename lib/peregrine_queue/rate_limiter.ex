defmodule PeregrineQueue.JobRateLimiter do
  use GenServer
  @rate_limit 10   # Maximum jobs per minute
  @time_window 60_000  # Time window in milliseconds (60 seconds)

  def start_link(_) do
    :ets.new(:job_rate_limiter, [:named_table, :public, :set])
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def can_execute?(queue_name) do
    now = :erlang.system_time(:millisecond)

    executions = :ets.lookup(:job_rate_limiter, queue_name)
    |> case do
      [] -> []
      [{_, timestamps}] -> timestamps
    end

    recent_executions = Enum.filter(executions, fn timestamp -> now - timestamp < @time_window end)

    if length(recent_executions) < @rate_limit do
      :ets.insert(:job_rate_limiter, {queue_name, [now | recent_executions]})
      :allowed
    else
      :denied
    end
  end
end
