defmodule PeregrineQueue.JobDataService do
  import Ecto.Query
  alias PeregrineQueue.JobData
  alias PeregrineQueue.Repo

  def get_job_data_by_oban_id(oban_id) do
    Repo.one(from(j in JobData, where: j.oban_id == ^oban_id))
  end

  def update_job_data(job_data, attrs) do
    JobData.changeset(job_data, attrs)
    |> Repo.update()
  end
end
