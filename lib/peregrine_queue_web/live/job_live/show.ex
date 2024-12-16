defmodule PeregrineQueueWeb.JobLive.Show do
  alias PeregrineQueue.JobDataService
  alias PeregrineQueue.DateTimeFormatter
  use PeregrineQueueWeb, :live_view
  use PeregrineQueueWeb.SharedSelects
  import PeregrineQueueWeb.Components.NotificationHandler


  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"job_id" => job_id}, _, socket) do
    job = JobDataService.get_job_data_with_oban_job(job_id)
    IO.inspect(job)
    {:noreply, assign(socket, job: job, global_notifications: [])}
  end

end
