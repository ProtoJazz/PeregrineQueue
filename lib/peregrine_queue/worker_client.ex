defmodule PeregrineQueue.WorkerClient do
  alias Queue.QueueService.Stub
  alias Queue.{DispatchWorkRequest, DispatchWorkResponse}
  def start_link(address) do
    GRPC.Stub.connect(address)
  end

  def dispatch_work(channel, data, queue_name, job_id) do
    request = %DispatchWorkRequest{
      job_id: job_id,
      queue_name: queue_name,
      data: data
    }

    case Stub.dispatch_work(channel, request) do
      {:ok, %DispatchWorkResponse{status: status}} ->
        IO.puts("Dispatch Work Response: #{status}")
        {:ok, status}

      {:error, reason} ->
        IO.puts("Failed to dispatch work: #{reason}")
        {:error, reason}
    end
  end
end
