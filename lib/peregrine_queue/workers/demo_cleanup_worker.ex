defmodule PeregrineQueue.Workers.DemoCleanup do
  use Oban.Worker, queue: :system, max_attempts: 1

  alias PeregrineQueue.Repo
  alias PeregrineQueue.JobData
  alias Oban.Job

  @impl Oban.Worker
  def perform(_job) do
    delete_all(JobData)
    delete_all(Job)
    :ok
  end

  defp delete_all(schema) do
    case Repo.delete_all(schema) do
      {count, _} ->
        IO.puts("Deleted #{count} rows from #{inspect(schema)}")
        :ok
    end
  end
end
