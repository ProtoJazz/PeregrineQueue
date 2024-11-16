defmodule PeregrineQueueWeb.DashboardLive.Index do
  use PeregrineQueueWeb, :live_view

  alias PeregrineQueue.Admin
  alias PeregrineQueue.Admin.Dashboard

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

end
