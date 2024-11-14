defmodule PeregrineQueue.DynamicQueue do
  alias PeregrineQueue.Workers.GenericWorker

  def enqueue_job(queue_name, data) do
    # Fetch queues from the environment or config to ensure the queue exists
    all_queues =
      Application.get_env(:peregrine_queue, PeregrineQueue, %{push_queues: [], pull_queues: []})
      |> (&(&1[:push_queues] ++ &1[:pull_queues])).()
    pull_queues = Application.get_env(:peregrine_queue, PeregrineQueue, %{}).pull_queues
    push_queues = Application.get_env(:peregrine_queue, PeregrineQueue, %{}).push_queues
    pull_job = Enum.find(pull_queues, fn queue -> queue.name == queue_name end)
    push_job = Enum.find(push_queues, fn queue -> queue.name == queue_name end)

    case {pull_job, push_job} do
      {nil, nil} ->
        {:error, "Queue #{queue_name} is not configured"}
      {nil, _} ->
        enqueue_push_job(queue_name, data)
      {_, nil} ->
        enqueue_pull_job(queue_name, data)
    end
  end

  defp enqueue_pull_job(queue_name, data) do
    make_job_data(nil, data, queue_name)

    {:ok, "Job enqueued"}
  end

  defp make_job_data(oban_job_id, data, queue_name) do
    %PeregrineQueue.JobData{}
    |> PeregrineQueue.JobData.changeset(%{oban_id: oban_job_id, payload: data, queue_name: queue_name, status: :pending, worker_id: nil, worker_address: nil})
    |> PeregrineQueue.Repo.insert!()
  end

  defp enqueue_push_job(queue_name, data) do

    oban_job = %{"queue_name" => queue_name, "data" => data}
    |> GenericWorker.new(queue: String.to_atom(queue_name))
    |> Oban.insert!()

    make_job_data(oban_job.id, data, queue_name)

    {:ok, "Job enqueued"}
  end


end
