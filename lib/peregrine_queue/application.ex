defmodule PeregrineQueue.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    configure_oban()
    print_oban_queues()

    children = [
      # Start the Telemetry supervisor
      PeregrineQueueWeb.Telemetry,
      # Start the Ecto repository
      PeregrineQueue.Repo,
      {GRPC.Server.Supervisor,
       endpoint: PeregrineQueueWeb.GRPCEndpoint, port: 50051, start_server: true,  ip: {0,0,0,0,0,0,0,0}},
      {PeregrineQueue.WorkerRegistry, []},
      {PeregrineQueue.JobRateLimiter, []},
      # Start the PubSub system
      {Phoenix.PubSub, name: PeregrineQueue.PubSub},
      # Start Finch
      {Finch, name: PeregrineQueue.Finch},
      # Start the Endpoint (http/https)
      PeregrineQueueWeb.Endpoint,
      GrpcReflection,
      {Oban, Application.fetch_env!(:peregrine_queue, Oban)}
      # Start a worker by calling: PeregrineQueue.Worker.start_link(arg)
      # {PeregrineQueue.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PeregrineQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PeregrineQueueWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp configure_oban do
    queue_config_json = System.get_env("QUEUE_CONFIG") || "{}"

    {oban_config, push_queues, pull_queues} =
      case Jason.decode(queue_config_json, keys: :atoms) do

        {:ok, config} -> get_oban_queues_from_env(config)
        {:error, _} -> {[], []}
      end

    Application.put_env(:peregrine_queue, Oban, repo: PeregrineQueue.Repo, queues: oban_config)
    Application.put_env(:peregrine_queue, PeregrineQueue, push_queues: push_queues, pull_queues: pull_queues)
  end

  defp get_oban_queues_from_env(%{push_queues: push_queues, pull_queues: pull_queues}) do
      oban_queues =
        pull_queues ++ push_queues
        |> Enum.map(fn %{name: name, concurrency: concurrency} -> {String.to_atom(name), concurrency} end)

      {oban_queues, push_queues, pull_queues}
  end

  defp print_oban_queues do
    oban_config = Application.get_env(:peregrine_queue, Oban, [])
    queue_config = Application.get_env(:peregrine_queue, PeregrineQueue, %{push_queues: [], pull_queues: []})

    queue_names =
      Keyword.get(oban_config, :queues, [])
      |> Enum.map(fn {name, limit} -> "#{name}:#{limit}" end)

    IO.puts("Configured Oban Queues: #{inspect(queue_names)}")

    IO.inspect(queue_config, label: "Queue Config")
  end
end
