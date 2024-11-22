defmodule PeregrineQueue.WorkerClient do
  alias Queue.QueueService.Stub
  alias Queue.{DispatchWorkRequest, DispatchWorkResponse}
  require Logger


  def start_link(address) do
    # First resolve the IPv6 address
    case :inet.getaddr(to_charlist(String.split(address, ":") |> hd()), :inet6) do
      {:ok, ipv6_addr} ->
        ip_string = :inet.ntoa(ipv6_addr) |> to_string()
        port = String.split(address, ":") |> List.last() |> String.to_integer()

        Logger.info("Using resolved IPv6: [#{ip_string}]:#{port}")
        GRPC.Stub.connect(ip_string, port, [
          timeout: 5000,
          connect_timeout: 5000
        ])
      {:error, _} ->
        # Fallback to direct connection if IPv6 resolution fails
        case String.split(address, ":") do
          [host, port] ->
            Logger.info("Falling back to direct connection: #{host}:#{port}")
            GRPC.Stub.connect(host, String.to_integer(port), [
              timeout: 5000,
              connect_timeout: 5000
            ])
          _ ->
            Logger.error("Invalid address format: #{address}")
            {:error, :invalid_address}
        end
    end
  end

  def dispatch_work(channel, data, queue_name, job_id) do
    request = %DispatchWorkRequest{
      job_id: job_id,
      queue_name: queue_name,
      data: data
    }

    case Stub.dispatch_work(channel, request) do
      {:ok, %DispatchWorkResponse{status: status}} ->
        Logger.info("Dispatch Work Response: #{status}")
        {:ok, status}

      {:error, reason} ->
        Logger.error("Failed to dispatch work: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
