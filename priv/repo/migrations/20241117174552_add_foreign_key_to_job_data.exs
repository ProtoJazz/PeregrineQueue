defmodule PeregrineQueue.Repo.Migrations.AddForeignKeyToJobData do
  use Ecto.Migration

  def change do
    alter table(:job_data) do
      add :oban_job_id, references(:oban_jobs, on_delete: :delete_all)
      remove :oban_id
    end

    create index(:job_data, [:oban_job_id])
  end
end
