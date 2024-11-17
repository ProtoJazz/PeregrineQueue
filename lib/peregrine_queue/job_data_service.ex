defmodule PeregrineQueue.JobDataService do
  import Ecto.Query
  alias PeregrineQueue.JobData
  alias PeregrineQueue.Repo

  def get_job_data_by_oban_id(oban_id) do
    Repo.one(from(j in JobData, where: j.oban_id == ^oban_id))
  end

  def get_job_data_by_job_data_id(job_data_id) do
    Repo.one(from(j in JobData, where: j.id == ^job_data_id))
  end

  def get_next_job_data(queue) do
    next_job = Repo.one(
      from(j in JobData,
        where: j.queue_name == ^queue,
        where: j.status == :pending,
        order_by: [asc: j.inserted_at],
        limit: 1
      )
    )
    job_count = Repo.aggregate(
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

  def get_jobs_for_time_range(start_time, end_time) do
    Repo.all(from(j in JobData, where: j.inserted_at >= ^start_time, where: j.inserted_at <= ^end_time))
  end

  def sort_jobs_for_chart(jobs) do
    Enum.reduce(jobs, %{}, fn job, acc ->
      acc
      |> Map.update(job.queue_name, %{
        pending: 0,
        active: 0,
        failed: 0,
        complete: 0
      }, fn status_counts ->
        Map.update!(status_counts, job.status, &(&1 + 1))
      end)
    end)
  end

  def transform_jobs_for_chart(sorted_jobs) do
    [
      %{
        name: "Successful",
        color: "#31C48D",
        data: Enum.map(sorted_jobs, fn {_queue_name, counts} ->
          Integer.to_string(Map.get(counts, :complete, 0))
        end)
      },
      %{
        name: "Failing",
        color: "#F05252",
        data: Enum.map(sorted_jobs, fn {_queue_name, counts} ->
          Integer.to_string(Map.get(counts, :failed, 0))
        end)
      },
      %{
        name: "Active",
        color: "#FFB020",
        data: Enum.map(sorted_jobs, fn {_queue_name, counts} ->
          Integer.to_string(Map.get(counts, :active, 0))
        end)
      },
      %{
        name: "Pending",
        color: "#6366F1",
        data: Enum.map(sorted_jobs, fn {_queue_name, counts} ->
          Integer.to_string(Map.get(counts, :pending, 0))
        end)
      }
    ]
  end
end
