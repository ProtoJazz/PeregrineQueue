defmodule PeregrineQueue.StartupTask do
  use GenServer

  alias Oban
  alias PeregrineQueue.Workers.DemoCleanup
  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    # Schedule the task after initialization
    Process.send_after(self(), :insert_job, 1_000) # 1 second delay
    {:ok, %{}}
  end

  @impl true
  def handle_info(:insert_job, state) do
    if System.get_env("DISPLAY_DEMO") == "true" do
      %{}
      |> DemoCleanup.new(queue: :system)
      |> Oban.insert!()

      IO.puts("DemoCleanup job inserted into :system queue.")
    end

    {:noreply, state} # Do not terminate the GenServer
  end
end
