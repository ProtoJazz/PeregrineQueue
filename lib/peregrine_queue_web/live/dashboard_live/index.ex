defmodule PeregrineQueueWeb.DashboardLive.Index do
  use PeregrineQueueWeb, :live_view
  import PeregrineQueueWeb.Components.JobsTable
  import PeregrineQueueWeb.Components.JobStats
  import PeregrineQueueWeb.Components.JobsChart
  import PeregrineQueueWeb.Components.NotificationHandler
  use PeregrineQueueWeb.SharedSelects

  alias PeregrineQueue.JobDataService
  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PeregrineQueue.PubSub, "job_events")
    end
    days_back = 7
    flop_params = %{"page" => 1, "page_size" => 10, "order_by" => ["scheduled_at"], "order_directions" => ["desc"]}
    socket = refresh_data(socket, flop_params, days_back)
    socket = socket |> assign(selected_jobs: [], global_notifications: [])
    {:ok, socket}
  end

  def refresh_data(socket, flop_params, days_back) do
    time_range = %{start_time: DateTime.utc_now() |> DateTime.add(-1 * days_back, :day), end_time: DateTime.utc_now()}
    {:ok, %{jobs: jobs, meta: meta}} = JobDataService.get_paginated_jobs(flop_params)
    {series_data, categories, jobs_stats, jobs_stats_data} = get_data_for_jobs(time_range)
    socket
    |> assign(jobs: jobs, series_data: series_data, categories: categories, jobs_stats: jobs_stats, meta: meta, time_range: time_range, days_back: days_back)
    |> push_event("chart-data", %{series_data: series_data, categories: categories, chart_height: 50 * Kernel.map_size(jobs_stats_data), chart_links: Enum.map(categories, fn category -> "/queues/#{category}" end)})
  end

  def get_data_for_jobs(time_range) do
    jobs_stats_data = JobDataService.get_status_counts_for_time_range(time_range)
    series_data = JobDataService.transform_jobs_for_chart(jobs_stats_data)

    categories =  jobs_stats_data |> Map.keys()

    jobs_stats = Enum.reduce(jobs_stats_data, %{failed: 0, complete: 0, active: 0, pending: 0}, fn {_, job}, acc ->
      %{failed: acc.failed + job.failed, complete: acc.complete + job.complete, active: acc.active + job.active, pending: acc.pending + job.pending}
    end)

    {series_data, categories, jobs_stats, jobs_stats_data}
  end

  @impl true
  def handle_event("range_adjust", %{"days_back" => days_back}, %{assigns: %{meta: meta}} = socket) do
    days_back = String.to_integer(days_back)
    flop_params = %{"page" => meta.current_page, "page_size" => meta.page_size, "order_by" => meta.flop.order_by, "order_directions" => meta.flop.order_directions}
    socket = refresh_data(socket, flop_params, days_back)
    {:noreply, socket}
  end

  @impl true
  def handle_event("page", %{"page" => page}, %{assigns: %{meta: meta}} = socket) do
    flop_params = %{"page" => page, "page_size" => meta.page_size, "order_by" => ["scheduled_at"], "order_directions" => ["desc"]}

    {:ok, %{jobs: jobs, meta: meta}} = JobDataService.get_paginated_jobs(flop_params)

    {:noreply, assign(socket, jobs: jobs, meta: meta)}
  end

  @impl true
  def handle_info(%{type: :refresh_jobs}, %{assigns: %{meta: meta, days_back: days_back}} = socket) do
    flop_params = %{"page" => meta.current_page, "page_size" => meta.page_size, "order_by" => meta.flop.order_by, "order_directions" => meta.flop.order_directions}
    socket = refresh_data(socket, flop_params, days_back)
    {:noreply, socket}
  end



end
