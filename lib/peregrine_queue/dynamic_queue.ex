defmodule PeregrineQueue.DynamicQueue do
  alias PeregrineQueue.Workers.GenericWorker

  def enqueue_job(queue_name, data) do
    # Fetch queues from the environment or config to ensure the queue exists
    all_queues =
      Application.get_env(:peregrine_queue, PeregrineQueue, %{push_queues: [], pull_queues: []})
      |> (&(&1[:push_queues] ++ &1[:pull_queues])).()

    IO.inspect(all_queues, label: "Queues")

    queue = Enum.find(all_queues, fn queue -> queue.name == queue_name end)

    if queue do
      oban_job = %{"queue_name" => queue_name, "data" => data}
      |> GenericWorker.new(queue: String.to_atom(queue_name))
      |> Oban.insert!()


      %PeregrineQueue.JobData{}
      |> PeregrineQueue.JobData.changeset(%{oban_id: oban_job.id, payload: data, queue_name: queue_name, status: :pending, worker_id: nil, worker_address: nil})
      |> PeregrineQueue.Repo.insert!()

      {:ok, "Job enqueued"}

    else
      {:error, "Queue #{queue_name} is not configured"}
    end
  end
end
