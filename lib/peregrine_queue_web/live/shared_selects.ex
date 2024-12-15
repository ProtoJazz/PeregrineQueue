defmodule PeregrineQueueWeb.SharedSelects do
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
    end
  end
end
