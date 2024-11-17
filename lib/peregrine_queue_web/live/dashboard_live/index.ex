defmodule PeregrineQueueWeb.DashboardLive.Index do
      alias Oban.Job
  use PeregrineQueueWeb, :live_view

  alias PeregrineQueue.Admin
  alias PeregrineQueue.Admin.Dashboard
  alias PeregrineQueue.JobDataService

  @impl true
  def mount(_params, _session, socket) do
    jobs = JobDataService.get_jobs_for_time_range(DateTime.utc_now() |> DateTime.add(-7, :day), DateTime.utc_now())
    |> JobDataService.sort_jobs_for_chart()
    series_data = JobDataService.transform_jobs_for_chart(jobs)

    categories =  jobs |> Map.keys()

    IO.inspect(jobs, label: "Jobs")
    IO.inspect(series_data, label: "Series Data")
    IO.inspect(categories, label: "Categories")

    jobs_stats = Enum.reduce(jobs, %{failing_jobs: 0, successful_jobs: 0, active_jobs: 0, pending_jobs: 0}, fn {_, job}, acc ->
      %{failing_jobs: acc.failing_jobs + job.failed, successful_jobs: acc.successful_jobs + job.complete, active_jobs: acc.active_jobs + job.active, pending_jobs: acc.pending_jobs + job.pending}
    end)

    socket =
      socket
      |> assign(jobs: jobs, series_data: series_data, categories: categories, jobs_stats: jobs_stats)
      |> push_event("chart-data", %{series_data: series_data, categories: categories})
    {:ok, socket}
  end

end
