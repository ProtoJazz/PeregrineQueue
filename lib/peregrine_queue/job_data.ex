defmodule PeregrineQueue.JobData do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:queue_name, :status, :worker_id, :worker_address, :inserted_at],
    sortable: [:queue_name, :status, :worker_id, :worker_address, :inserted_at, :scheduled_at]
  }

  schema "job_data" do
    field :payload, :string
    field :queue_name, :string
    field :status, Ecto.Enum, values: [:pending, :active, :failed, :complete]
    field :worker_address, :string
    field :worker_id, :string
    field :scheduled_at, :utc_datetime, virtual: true

    belongs_to :oban_job, Oban.Job, foreign_key: :oban_job_id

    timestamps()
  end

  @doc false
  def changeset(job_data, attrs) do
    job_data
    |> cast(attrs, [:oban_job_id, :payload, :status, :worker_id, :worker_address, :queue_name])
    |> validate_required([:payload, :status])
  end
end
