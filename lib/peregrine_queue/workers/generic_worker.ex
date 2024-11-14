defmodule PeregrineQueue.Workers.GenericWorker do
  alias PeregrineQueue.JobDataService
  alias PeregrineQueue.JobData
  use Oban.Worker
  alias PeregrineQueue.WorkerClient
  alias PeregrineQueue.Repo
  alias PeregrineQueue.JobRateLimiter
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"queue_name" => queue_name, "data" => data}} = job) do
    # Lockout the job while we attempt it
    IO.inspect(job, label: "Job")

    case JobRateLimiter.can_execute?(queue_name) do

      :allowed ->
        workers = PeregrineQueue.QueueService.get_workers_for_queue(queue_name)

        case workers do
          [] ->
            IO.puts("No workers registered for queue #{queue_name}")
            {:error, "No workers available"}

          _ ->
            IO.puts("Workers found for queue #{queue_name}")
            job_data = JobDataService.get_job_data_by_oban_id(job.id)
            dispatched_worker = Enum.reduce_while(0..Enum.count(workers), nil, fn x, acc ->

              attempt_worker = Enum.at(workers, x)

              IO.puts("Attempting worker: #{inspect(attempt_worker)}")
              {:ok, channel} = WorkerClient.start_link(attempt_worker.worker_address)

              IO.puts("Channel: #{inspect(channel)}")
              {status, response} = WorkerClient.dispatch_work(channel, data, queue_name, job.id)
              IO.inspect(response, label: " dispatch work Response")
              IO.inspect(status, label: "Status")

              if(status == :ok) do
                JobDataService.update_job_data(job_data, %{worker_address: attempt_worker.worker_address, worker_id: attempt_worker.worker_id, status: String.to_atom(response) })
                {:halt, attempt_worker}
              else
                {:cont, nil}
              end


            end)

            # Enum.each(workers, fn worker ->
            #   # Check worker's batch size capability, then send jobs in chunks
            #   batch_size = Map.get(worker, :batch_size, 1)
            #   job_batches = Enum.chunk_every([], batch_size)

            #   Enum.each(job_batches, fn batch ->
            #     nil
            #     # send_batch_to_worker(worker.address, batch)
            #   end)
            # end)

            {:ok, "Job dispatched"}
          end
        :denied ->
          IO.puts("Rate limit exceeded for queue #{queue_name}")
          {:error, "Rate limit exceeded"}
    end
  end
end
