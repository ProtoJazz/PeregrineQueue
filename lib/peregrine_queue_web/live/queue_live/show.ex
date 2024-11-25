defmodule PeregrineQueueWeb.QueueLive.Show do
  alias PeregrineQueue.JobDataService
  use PeregrineQueueWeb, :live_view
  import PeregrineQueueWeb.Components.JobsTable

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"name" => name}, _, socket) do
    # jobs = JobDataService.get_jobs_for_queue(name)

    flop_params = %{
      "page" => 1,
      "page_size" => 10,
      "order_by" => ["scheduled_at"],
      "order_directions" => ["desc"],
      "filters" => [%{field: :queue_name, op: :=~, value: name}]
    }

    socket = refresh_data(socket, flop_params, name)

    {:noreply, socket}
  end

  def refresh_data(socket, flop_params, name) do
    time_range = %{
      start_time: DateTime.utc_now() |> DateTime.add(-7, :day),
      end_time: DateTime.utc_now()
    }

    {:ok, %{jobs: jobs, meta: meta}} =
      JobDataService.get_paginated_jobs_for_time_range(time_range, flop_params)

    if meta.total_count == 0 do
      jobs_stats = %{pending: 0, active: 0, failed: 0, complete: 0}

      {:noreply,
       socket |> assign(queue_name: name, jobs: jobs, meta: meta, jobs_stats: jobs_stats)}
    else
      jobs_stats = JobDataService.get_status_counts_for_time_range(time_range, [name])
      chart_data = JobDataService.transform_jobs_for_chart(jobs_stats)
      categories = jobs_stats |> Map.keys()

      socket =
        socket
        |> assign(
          jobs: jobs,
          queue_name: name,
          jobs_stats: jobs_stats |> Map.get(name),
          chart_data: chart_data,
          meta: meta,
          time_range: time_range
        )
        |> push_event("chart-data", %{
          series_data: chart_data,
          categories: categories,
          chart_height: 100,
          chart_links: Enum.map(categories, fn category -> "/queues/#{category}" end)
        })
    end
  end

  def get_data_for_jobs(jobs, time_range, name) do
    jobs_stats = JobDataService.get_status_counts_for_time_range(time_range, [name])
    chart_data = JobDataService.transform_jobs_for_chart(jobs_stats)
    categories = jobs_stats |> Map.keys()

    {categories, jobs_stats, chart_data}
  end

  def handle_info(
        %{type: :refresh_jobs},
        %{assigns: %{time_range: time_range, meta: meta, queue_name: name}} = socket
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
    socket = refresh_data(socket, flop_params, name)
    {:noreply, socket}
  end

  def handle_event("page", %{"page" => page}, %{assigns: %{time_range: time_range, meta: meta}} = socket) do
    flop_params = %{"page" => page, "page_size" => meta.page_size, "order_by" => ["scheduled_at"], "order_directions" => ["desc"]}

    {:ok, %{jobs: jobs, meta: meta}} = JobDataService.get_paginated_jobs_for_time_range(time_range, flop_params)

    {:noreply, assign(socket, jobs: jobs, meta: meta)}
  end

  defp page_title(:show), do: "Show Queue"
  defp page_title(:edit), do: "Edit Queue"
end
