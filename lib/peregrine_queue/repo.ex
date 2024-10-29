defmodule PeregrineQueue.Repo do
  use Ecto.Repo,
    otp_app: :peregrine_queue,
    adapter: Ecto.Adapters.Postgres
end
