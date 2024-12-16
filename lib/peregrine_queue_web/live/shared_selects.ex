defmodule PeregrineQueueWeb.SharedSelects do
  alias PeregrineQueue.JobDataService
  alias PeregrineQueue.EnqueueService
  defmacro __using__(_opts) do
    quote do
      @impl true
      def handle_event("select_all_jobs",%{"value" => "on"}, socket) do
        {:noreply, assign(socket, selected_jobs: socket.assigns.jobs)}
      end

      @impl true
      def handle_event("select_all_jobs", %{}, socket) do
        {:noreply, assign(socket, selected_jobs: [])}
      end

      def handle_event("select_job", %{"job-id" => job_id, "value" => "on"}, %{assigns: %{jobs: jobs, selected_jobs: selected_jobs}} = socket) do
        job_id = String.to_integer(job_id)
        job = Enum.find(jobs, & &1.id == job_id)

        new_selected_jobs = if Enum.member?(selected_jobs, job) do
          Enum.reject(selected_jobs, & &1 == job)
        else
          [job | selected_jobs]
        end

        {:noreply, assign(socket, selected_jobs: new_selected_jobs)}
      end

      def handle_event("select_job", %{"job-id" => job_id}, %{assigns: %{jobs: jobs, selected_jobs: selected_jobs}} = socket) do
        job_id = String.to_integer(job_id)
        job = Enum.find(jobs, & &1.id == job_id)

        new_selected_jobs = if Enum.member?(selected_jobs, job) do
          Enum.reject(selected_jobs, & &1 == job)
        else
          selected_jobs
        end
        {:noreply, assign(socket, selected_jobs: new_selected_jobs)}
      end

      def handle_event("retry_jobs", %{}, %{assigns: %{selected_jobs: selected_jobs}} = socket) do
        Enum.each(selected_jobs, &JobDataService.retry_job_data(&1))
        notification = %{id: :erlang.unique_integer([:positive]), message: "Retrying jobs"}
        {:noreply, assign(socket, selected_jobs: [], global_notifications: [notification | socket.assigns.global_notifications])}
      end

      def handle_event("remove_notification", %{"id" => id}, socket) do
        notifications =
          Enum.reject(socket.assigns.global_notifications, fn n -> n.id == String.to_integer(id) end)

        {:noreply, assign(socket, global_notifications: notifications)}
      end

      def handle_event("spawn_demo_event", _, socket) do
        notification = %{id: :erlang.unique_integer([:positive]), message: "Demo event triggered!"}
        IO.inspect(notification)


        EnqueueService.enqueue_job("media_update", "/var/bean/movies")
        EnqueueService.enqueue_job("data_sync", "/var/bean/movies")
       # EnqueueService.enqueue_job("web_scrapping", "/var/bean/movies")
        Phoenix.PubSub.broadcast(PeregrineQueue.PubSub, "job_events", %{type: :refresh_jobs})

        {:noreply, assign(socket, global_notifications: [notification | socket.assigns.global_notifications])}
      end


    end
  end
end
