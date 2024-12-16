defmodule PeregrineQueue.JobDataService do
  import Ecto.Query
  alias PeregrineQueue.JobData
  alias PeregrineQueue.Repo

  def get_job_data_by_oban_id(oban_job_id) do
    Repo.one(from(j in JobData, where: j.oban_job_id == ^oban_job_id))
  end

  def get_job_data_by_job_data_id(job_data_id) do
    Repo.one(from(j in JobData, where: j.id == ^job_data_id))
  end

  def get_job_data_with_oban_job(job_data_id) do
    Repo.one(from(j in JobData, where: j.id == ^job_data_id, preload: :oban_job))
  end

  def delete_job(job_data) do

    Repo.delete!(job_data)
    if(job_data.oban_job != nil) do
      Repo.delete!(job_data.oban_job)
    end
  end

  def retry_oban_job(oban_job) do
          oban_job
          |> Ecto.Changeset.change(%{
            state: "retryable",
            attempt: oban_job.attempt - 1,
            scheduled_at: DateTime.utc_now(),
            errors: []
          })
          |> Repo.update!()
  end

  def retry_job_data(job_data) do
    Repo.transaction(fn ->
      if(job_data.oban_job != nil) do
          retry_oban_job(job_data.oban_job)
      end
      job_data =
        update_job_data(job_data, %{
          status: :pending,
          worker_id: nil,
          worker_address: nil
        })
      {:ok, job_data}
    end)
  end

  def get_next_job_data(queue) do
    next_job =
      Repo.one(
        from(j in JobData,
          where: j.queue_name == ^queue,
          where: j.status == :pending,
          order_by: [asc: j.inserted_at],
          limit: 1
        )
      )

    job_count =
      Repo.aggregate(
        from(j in JobData,
          where: j.status in [:active]
        ),
        :count,
        :id
      )

    {next_job, job_count}
  end

  def update_job_data(job_data, attrs) do
    JobData.changeset(job_data, attrs)
    |> Repo.update()
  end

  @spec get_jobs_for_time_range(any(), any()) :: any()
  def get_jobs_for_time_range(start_time, end_time) do
    Repo.all(
      from(j in JobData, where: j.inserted_at >= ^start_time, where: j.inserted_at <= ^end_time, preload: :oban_job)
    )
  end
  def get_paginated_jobs_for_time_range(%{start_time: start_time, end_time: end_time}, flop_params) do
    base_query =
      from j in JobData,
        left_join: oj in assoc(j, :oban_job),
        where: j.inserted_at >= ^start_time and j.inserted_at <= ^end_time,
        preload: [oban_job: oj]

    query = if flop_params["order_by"] == ["scheduled_at"] do
      direction = (flop_params["order_directions"] || ["asc"]) |> hd() |> String.to_atom()

      from [j, oj] in base_query,
        order_by: [{^direction, coalesce(oj.scheduled_at, ^DateTime.from_unix!(253_402_300_799))}]
    else
      base_query
    end

    case Flop.validate_and_run(query, Map.drop(flop_params, ["order_by", "order_directions"])) do
      {:ok, {results, meta}} ->
        {:ok, %{jobs: results, meta: meta}}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def get_paginated_jobs(flop_params) do
    base_query =
      from j in JobData,
        left_join: oj in assoc(j, :oban_job),
        preload: [oban_job: oj]

    query = if flop_params["order_by"] == ["scheduled_at"] do
      direction = (flop_params["order_directions"] || ["asc"]) |> hd() |> String.to_atom()

      from [j, oj] in base_query,
        order_by: [{^direction, coalesce(oj.scheduled_at, ^DateTime.from_unix!(253_402_300_799))}]
    else
      base_query
    end

    case Flop.validate_and_run(query, Map.drop(flop_params, ["order_by", "order_directions"])) do
      {:ok, {results, meta}} ->
        {:ok, %{jobs: results, meta: meta}}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
  def get_status_counts_for_time_range(%{start_time: start_time, end_time: end_time}, queue_names \\ []) do
    jobs_status_counts = if Enum.count(queue_names) > 0 do
      Repo.all(
        from j in JobData,
          where: j.inserted_at >= ^start_time and j.inserted_at <= ^end_time and j.queue_name in ^queue_names,
          group_by: [j.queue_name, j.status],
          select: {j.queue_name, j.status, count(j.id)}
      )
    else
      Repo.all(
        from j in JobData,
          where: j.inserted_at >= ^start_time and j.inserted_at <= ^end_time,
          group_by: [j.queue_name, j.status],
          select: {j.queue_name, j.status, count(j.id)}
      )
    end

    initial_acc =
      jobs_status_counts
      |> Enum.map(fn {queue_name, _status, _count} -> queue_name end)
      |> Enum.uniq()
      |> Map.new(fn queue_name ->
        {queue_name, %{pending: 0, active: 0, failed: 0, complete: 0}}
      end)

     Enum.reduce(jobs_status_counts, initial_acc, fn {queue_name, status, count}, acc ->
      queue_name_as_string = to_string(queue_name)
      status_as_atom = String.to_atom(to_string(status))

      Map.update(acc, queue_name_as_string, %{pending: 0, active: 0, failed: 0, complete: 0}, fn counts ->
        Map.put(counts, status_as_atom, count + Map.get(counts, status_as_atom, 0))
      end)
    end)
  end

  def transform_jobs_for_chart(sorted_jobs) do
    [
      %{
        name: "Successful",
        color: "#31C48D",
        data:
          Enum.map(sorted_jobs, fn {_queue_name, counts} ->
            Integer.to_string(Map.get(counts, :complete, 0))
          end)
      },
      %{
        name: "Failing",
        color: "#F05252",
        data:
          Enum.map(sorted_jobs, fn {_queue_name, counts} ->
            Integer.to_string(Map.get(counts, :failed, 0))
          end)
      },
      %{
        name: "Active",
        color: "#FFB020",
        data:
          Enum.map(sorted_jobs, fn {_queue_name, counts} ->
            Integer.to_string(Map.get(counts, :active, 0))
          end)
      },
      %{
        name: "Pending",
        color: "#6366F1",
        data:
          Enum.map(sorted_jobs, fn {_queue_name, counts} ->
            Integer.to_string(Map.get(counts, :pending, 0))
          end)
      }
    ]
  end
end
