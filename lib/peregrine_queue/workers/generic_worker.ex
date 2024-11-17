defmodule PeregrineQueue.Workers.GenericWorker do
  alias PeregrineQueue.JobDataService
  alias PeregrineQueue.JobData
  use Oban.Worker
  alias PeregrineQueue.WorkerClient
  alias PeregrineQueue.Repo
  alias PeregrineQueue.JobRateLimiter

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"queue_name" => queue_name, "data" => data, "job_data_id" => job_id}} = job) do
    IO.puts("Performing job for queue #{queue_name}")
    try do
      case JobRateLimiter.can_execute?(queue_name) do
        :allowed ->
          handle_work(queue_name, data, job_id)

        :denied ->
          IO.puts("Rate limit exceeded for queue #{queue_name}")
          {:error, "Rate limit exceeded"}
      end
    rescue
      exception ->
        error_message = "An error occurred during job execution: #{inspect(exception)}"
        IO.puts(error_message)
        update_job_data_error(job_id, error_message)
        {:error, error_message}
    end
  end

  defp handle_work(queue_name, data, job_id) do
    workers = PeregrineQueue.QueueServer.get_workers_for_queue(queue_name)

    case workers do
      [] ->
        IO.puts("No workers registered for queue #{queue_name}")
        {:error, "No workers available"}

      _ ->
        IO.puts("Workers found for queue #{queue_name}")
        job_data = JobDataService.get_job_data_by_job_data_id(job_id)

        dispatched_worker = Enum.reduce_while(workers, nil, fn worker, acc ->
          IO.puts("Attempting worker: #{inspect(worker)}")

          case WorkerClient.start_link(worker.worker_address) do
            {:ok, channel} ->
              {status, response} = WorkerClient.dispatch_work(channel, data, queue_name, job_data.id)
              IO.inspect(response, label: "Dispatch Work Response")
              IO.inspect(status, label: "Status")

              if status == :ok do
                JobDataService.update_job_data(job_data, %{
                  worker_address: worker.worker_address,
                  worker_id: worker.worker_id,
                  status: String.to_atom(response)
                })

                {:halt, worker}
              else
                {:cont, nil}
              end

            {:error, error} ->
              IO.puts("Error connecting to worker: #{inspect(error)}")
              {:cont, nil}
          end
        end)

        if dispatched_worker do
          {:ok, "Job dispatched"}
        else
          {:error, "Failed to dispatch job to any worker"}
        end
    end
  end

  defp update_job_data_error(job_id, error_message) do
    job_data = JobDataService.get_job_data_by_job_data_id(job_id)
    JobDataService.update_job_data(job_data, %{status: :failed})
  end
end
