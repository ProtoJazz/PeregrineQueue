defmodule PeregrineQueue.DynamicQueue do
  alias PeregrineQueue.Workers.GenericWorker

  def enqueue_job(queue_name, data) do
    # Fetch queues from the environment or config to ensure the queue exists
    queue_config_json = System.get_env("OBAN_QUEUE_CONFIG") || "{}"
    queue_config = Jason.decode!(queue_config_json)

    # Verify if the specified queue exists in configuration
    if Map.has_key?(queue_config, queue_name) do
      Oban.insert!(%Oban.Job{
        # Dynamically use queue name
        queue: String.to_atom(queue_name),
        worker: GenericWorker,
        args: %{"queue_name" => queue_name, "data" => data}
      })
    else
      {:error, "Queue #{queue_name} is not configured"}
    end
  end
end
