defmodule PeregrineQueueWeb.QueueLive.Show do
  alias PeregrineQueue.JobDataService
  use PeregrineQueueWeb, :live_view
  use PeregrineQueueWeb.SharedSelects
  import PeregrineQueueWeb.Components.JobsTable
  import PeregrineQueueWeb.Components.JobStats
  import PeregrineQueueWeb.Components.JobsChart
  import PeregrineQueueWeb.Components.NotificationHandler

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"name" => name}, _, socket) do
    days_back = 7
    flop_params = %{
      "page" => 1,
      "page_size" => 10,
      "order_by" => ["scheduled_at"],
      "order_directions" => ["desc"],
      "filters" => [%{field: :queue_name, op: :=~, value: name}]
    }

    socket = refresh_data(socket, flop_params, name, days_back) |> assign(selected_jobs: [], global_notifications: [])

    {:noreply, socket}
  end

  def refresh_data(socket, flop_params, name, days_back) do
    time_range = %{
      start_time: DateTime.utc_now() |> DateTime.add(-1 * days_back, :day),
      end_time: DateTime.utc_now()
    }

    {:ok, %{jobs: jobs, meta: meta}} =
      JobDataService.get_paginated_jobs(flop_params)

    if meta.total_count == 0 do
      jobs_stats = %{pending: 0, active: 0, failed: 0, complete: 0}

       socket |> assign(queue_name: name, jobs: jobs, meta: meta, jobs_stats: jobs_stats, days_back: days_back, time_range: time_range)
    else
      jobs_stats = JobDataService.get_status_counts_for_time_range(time_range, [name])
      chart_data = JobDataService.transform_jobs_for_chart(jobs_stats)
      categories = jobs_stats |> Map.keys()
      chart_job_stats = jobs_stats |> Map.get(name)

      chart_job_stats = if chart_job_stats == nil do %{pending: 0, active: 0, failed: 0, complete: 0} else chart_job_stats end
        socket
        |> assign(
          jobs: jobs,
          queue_name: name,
          jobs_stats: chart_job_stats,
          chart_data: chart_data,
          meta: meta,
          time_range: time_range,
          days_back: days_back
        )
        |> push_event("chart-data", %{
          series_data: chart_data,
          categories: categories,
          chart_height: 100,
          chart_links: Enum.map(categories, fn category -> "/queues/#{category}" end)
        })
    end
  end

  @impl true
  def handle_info(
        %{type: :refresh_jobs},
        %{assigns: %{meta: meta, queue_name: name, days_back: days_back}} = socket
      ) do
    filters =
      Enum.map(meta.flop.filters, fn
        %Flop.Filter{} = filter -> Map.from_struct(filter)
        other -> other
      end)

    flop_params = %{
      "page" => meta.current_page,
      "page_size" => meta.page_size,
      "order_by" => meta.flop.order_by,
      "order_directions" => meta.flop.order_directions,
      "filters" => filters
    }
    socket = refresh_data(socket, flop_params, name, days_back)
    {:noreply, socket}
  end

  @impl true
  def handle_event("page", %{"page" => page}, %{assigns: %{time_range: time_range, meta: meta}} = socket) do
    flop_params = %{"page" => page, "page_size" => meta.page_size, "order_by" => ["scheduled_at"], "order_directions" => ["desc"]}

    {:ok, %{jobs: jobs, meta: meta}} = JobDataService.get_paginated_jobs_for_time_range(time_range, flop_params)

    {:noreply, assign(socket, jobs: jobs, meta: meta)}
  end

  @impl true
  def handle_event("range_adjust", %{"days_back" => days_back}, %{assigns: %{meta: meta, queue_name: queue_name}} = socket) do
    IO.inspect("QUEUE NAME")
    IO.inspect(queue_name)
    days_back = String.to_integer(days_back)
    flop_params = %{"page" => meta.current_page, "page_size" => meta.page_size, "order_by" => meta.flop.order_by, "order_directions" => meta.flop.order_directions}
    socket = refresh_data(socket, flop_params, queue_name, days_back)
    {:noreply, socket}
  end

end
