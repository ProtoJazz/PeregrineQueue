defmodule PeregrineQueue.Repo.Migrations.CreateJobData do
  use Ecto.Migration

  def change do
    create table(:job_data) do
      add :oban_id, :integer
      add :payload, :string
      add :status, :string
      add :worker_id, :string
      add :worker_address, :string
      add :queue_name, :string

      timestamps()
    end
  end
end
