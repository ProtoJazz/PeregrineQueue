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
    time_range = %{
      start_time: DateTime.utc_now() |> DateTime.add(-7, :day),
      end_time: DateTime.utc_now()
    }

    flop_params = %{
      "page" => 1,
      "page_size" => 10,
      "order_by" => ["inserted_at"],
      "order_directions" => ["asc"],
      "filters" => [%{field: :queue_name, op: :=~, value: name}]
    }

    {:ok, %{jobs: jobs, meta: meta}} =
      JobDataService.get_paginated_jobs_for_time_range(time_range, flop_params)

    if meta.total_count == 0 do
      jobs_stats = %{pending: 0, active: 0, failed: 0, complete: 0}
      {:noreply, socket |> assign(queue_name: name, jobs: jobs, meta: meta, jobs_stats: jobs_stats)}
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
          meta: meta
        )
        |> push_event("chart-data", %{
          series_data: chart_data,
          categories: categories,
          chart_height: 100,
          chart_links: Enum.map(categories, fn category -> "/queues/#{category}" end)
        })

      {:noreply, socket}
    end
  end

  defp page_title(:show), do: "Show Queue"
  defp page_title(:edit), do: "Edit Queue"
end
