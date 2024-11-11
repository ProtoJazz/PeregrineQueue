defmodule PeregrineQueue.Workers.GenericWorker do
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"queue_name" => queue_name, "data" => data}}) do
    # Lockout the job while we attempt it

    workers = PeregrineQueue.QueueService.get_workers_for_queue(queue_name)

    case workers do
      [] ->
        IO.puts("No workers registered for queue #{queue_name}")
        {:error, "No workers available"}

      _ ->
        IO.puts("Workers found for queue #{queue_name}")

        dispatched_worker = Enum.reduce_while(0..Enum.count(workers), nil, fn x, acc ->

          attempt_worker = Enum.at(workers, x)

          #send work through GRPC


          # if attempt_failed do
          #   IO.puts("Current value: #{x}")
          #   {:cont, nil} # Continue loop
          # else
          #   {:halt, attempt_worker} # Stop loop
          # end
        end)


        {:ok, "Job dispatched"}

        # Enum.each(workers, fn worker ->
        #   # Check worker's batch size capability, then send jobs in chunks
        #   batch_size = Map.get(worker, :batch_size, 1)
        #   job_batches = Enum.chunk_every([], batch_size)

        #   Enum.each(job_batches, fn batch ->
        #     nil
        #     # send_batch_to_worker(worker.address, batch)
        #   end)
        # end)
    end
  end
end
