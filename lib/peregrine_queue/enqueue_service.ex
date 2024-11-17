defmodule PeregrineQueue.EnqueueService do
  alias PeregrineQueue.Workers.GenericWorker

  def enqueue_job(queue_name, data) do
    config = Application.get_env(:peregrine_queue, PeregrineQueue, [])
    pull_queues = Keyword.get(config, :pull_queues, [])
    push_queues = Keyword.get(config, :push_queues, [])
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
    make_job_data(data, queue_name)
    {:ok, "Job enqueued"}
  end

  defp enqueue_push_job(queue_name, data) do
    job_data = make_job_data(data, queue_name)

    oban_job =
      %{"queue_name" => queue_name, "data" => data, "job_data_id" => job_data.id}
      |> GenericWorker.new(queue: String.to_atom(queue_name))
      |> Oban.insert!()

    update_job_data_with_oban_id(job_data, oban_job.id)

    {:ok, "Job enqueued"}
  end

  defp make_job_data(data, queue_name) do
    %PeregrineQueue.JobData{}
    |> PeregrineQueue.JobData.changeset(%{
      payload: data,
      queue_name: queue_name,
      status: :pending,
      worker_id: nil,
      worker_address: nil
    })
    |> PeregrineQueue.Repo.insert!()
  end

  defp update_job_data_with_oban_id(job_data, oban_job_id) do
    job_data
    |> PeregrineQueue.JobData.changeset(%{oban_job_id: oban_job_id})
    |> PeregrineQueue.Repo.update!()
  end


end
