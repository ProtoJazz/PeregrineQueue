defmodule PeregrineQueue.WorkerClient do
  alias Queue.QueueService.Stub
  alias Queue.{DispatchWorkRequest, DispatchWorkResponse}
  require Logger

  @timeout 15_000

  def start_link(address) do
    Logger.info("Initiating connection to: #{address}")

    connection_opts = [
      timeout: @timeout,
      connect_timeout: @timeout,
      adapter: GRPC.Client.Adapters.Mint,
      adapter_opts: [
        transport_opts: [
          mode: :active,
          inet6: true
        ]
      ]
    ]

    Logger.info("Connecting to #{address} with options: #{inspect(connection_opts)}")
    GRPC.Stub.connect(address, connection_opts)
  end

  def dispatch_work(channel, data, queue_name, job_id) do
    request = %DispatchWorkRequest{
      job_id: job_id,
      queue_name: queue_name,
      data: data
    }

    Logger.info("Preparing to dispatch work: #{inspect(request)}")

    try do
      case Stub.dispatch_work(channel, request, timeout: @timeout) do
        {:ok, %DispatchWorkResponse{} = response} ->
          Logger.info("Successful dispatch response: #{inspect(response)}")
          {:ok, response.status}

        {:error, reason} = error ->
          Logger.error("Dispatch error: #{inspect(reason)}")
          error
      end
    rescue
      e ->
        Logger.error("Exception during dispatch: #{Exception.message(e)}")
        Logger.error("#{Exception.format_stacktrace(__STACKTRACE__)}")
        {:error, :dispatch_failed}
    after
      GRPC.Stub.disconnect(channel)
    end
  end
end
