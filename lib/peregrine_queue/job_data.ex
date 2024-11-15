defmodule PeregrineQueue.JobData do
  use Ecto.Schema
  import Ecto.Changeset

  schema "job_data" do
    field :oban_id, :integer
    field :payload, :string
    field :queue_name, :string
    field :status, Ecto.Enum, values: [:pending, :active, :failed, :complete]
    field :worker_address, :string
    field :worker_id, :string

    timestamps()
  end

  @doc false
  def changeset(job_data, attrs) do
    job_data
    |> cast(attrs, [:oban_id, :payload, :status, :worker_id, :worker_address, :queue_name])
    |> validate_required([:payload, :status])
  end
end
