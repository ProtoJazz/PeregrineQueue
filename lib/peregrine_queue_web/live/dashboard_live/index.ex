defmodule PeregrineQueueWeb.DashboardLive.Index do
  use PeregrineQueueWeb, :live_view
  import PeregrineQueueWeb.Components.JobsTable

  alias PeregrineQueue.JobDataService
  @impl true
  def mount(_params, _session, socket) do

    time_range = %{start_time: DateTime.utc_now() |> DateTime.add(-7, :day), end_time: DateTime.utc_now()}
    flop_params = %{"page" => 1, "page_size" => 10, "order_by" => ["inserted_at"], "order_directions" => ["asc"]}

    {:ok, %{jobs: jobs, meta: meta}} = JobDataService.get_paginated_jobs_for_time_range(time_range, flop_params)
    jobs_stats_data = JobDataService.get_status_counts_for_time_range(time_range)
    series_data = JobDataService.transform_jobs_for_chart(jobs_stats_data)

    categories =  jobs_stats_data |> Map.keys()

    jobs_stats = Enum.reduce(jobs_stats_data, %{failing_jobs: 0, successful_jobs: 0, active_jobs: 0, pending_jobs: 0}, fn {_, job}, acc ->
      %{failing_jobs: acc.failing_jobs + job.failed, successful_jobs: acc.successful_jobs + job.complete, active_jobs: acc.active_jobs + job.active, pending_jobs: acc.pending_jobs + job.pending}
    end)
    socket =
      socket
      |> assign(jobs: jobs, series_data: series_data, categories: categories, jobs_stats: jobs_stats, meta: meta, time_range: time_range)
      |> push_event("chart-data", %{series_data: series_data, categories: categories, chart_height: 50 * Map.size(jobs_stats_data), chart_links: Enum.map(categories, fn category -> "/queues/#{category}" end)})
    {:ok, socket}
  end

  def handle_event("page", %{"page" => page}, %{assigns: %{time_range: time_range, meta: meta}} = socket) do
    flop_params = %{"page" => page, "page_size" => meta.page_size, "order_by" => ["inserted_at"], "order_directions" => ["asc"]}

    {:ok, %{jobs: jobs, meta: meta}} = JobDataService.get_paginated_jobs_for_time_range(time_range, flop_params)

    {:noreply, assign(socket, jobs: jobs, meta: meta)}
  end

end
