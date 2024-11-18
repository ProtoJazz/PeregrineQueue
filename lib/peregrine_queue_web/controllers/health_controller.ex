defmodule PeregrineQueueWeb.HealthController do
  use PeregrineQueueWeb, :controller

  def check(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
