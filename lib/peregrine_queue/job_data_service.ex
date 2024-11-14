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
    next_job = Repo.one(from(j in JobData, where: j.queue_name == ^queue, where: j.status == :pending, order_by: [asc: j.inserted_at]))

    job_count = Repo.aggregate(
      from(j in JobData,
        where: j.status in [:pending, :active]
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
end
