defmodule PeregrineQueueWeb.Components.GlobalEvents do
  use PeregrineQueueWeb, :live_component
  alias PeregrineQueue.EnqueueService
  alias PeregrineQueue.JobData
  alias PeregrineQueue.JobDataService

  def mount(socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PeregrineQueue.PubSub, "job_events")
    end

    {:ok, assign(socket, global_notifications: [])}
  end

  def handle_event("spawn_demo_event", _, socket) do
    notification = %{id: :erlang.unique_integer([:positive]), message: "Demo event triggered!"}
    IO.inspect(notification)


    EnqueueService.enqueue_job("media_update", "/var/bean/movies")
   # EnqueueService.enqueue_job("data_sync", "/var/bean/movies")
   # EnqueueService.enqueue_job("web_scrapping", "/var/bean/movies")
    Phoenix.PubSub.broadcast(PeregrineQueue.PubSub, "job_events", %{type: :refresh_jobs})

    {:noreply, assign(socket, global_notifications: [notification | socket.assigns.global_notifications])}
  end
  def handle_event("remove_notification", %{"id" => id}, socket) do
    notifications =
      Enum.reject(socket.assigns.global_notifications, fn n -> n.id == String.to_integer(id) end)

    {:noreply, assign(socket, global_notifications: notifications)}
  end

  def handle_event("retry_job", %{"id" => id}, socket) do
    IO.inspect("Retrying job with id #{id}")

    job_id = String.to_integer(id)
    job_data = JobDataService.get_job_data_with_oban_job(job_id)

    JobDataService.retry_job_data(job_data)
    notification = %{id: :erlang.unique_integer([:positive]), message: "Retrying job: #{id}"}
    Phoenix.PubSub.broadcast(PeregrineQueue.PubSub, "job_events", %{type: :refresh_jobs})
    {:noreply, assign(socket, global_notifications: [notification | socket.assigns.global_notifications])}

  end


  def render(assigns) do
    ~H"""
    <span id="global-event-handler">
      <div class="fixed bottom-4 right-4 space-y-2">
      <%= for notification <- @global_notifications do %>
        <div
          id={"toast-#{notification.id}"}
          phx-hook="Toast"
          phx-click="remove_notification"
          data-id={notification.id}
          phx-target="#global-event-handler"
          phx-value-id={notification.id}
          class="flex items-center w-full max-w-xs p-4 text-gray-500 bg-white rounded-lg shadow dark:text-gray-400 dark:bg-gray-800"
          role="alert"
        >
          <div class="inline-flex items-center justify-center flex-shrink-0 w-8 h-8 text-blue-500 bg-blue-100 rounded-lg dark:bg-blue-800 dark:text-blue-200">
            <!-- Icon -->
            <svg aria-hidden="true" class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
              <path fill-rule="evenodd" d="M16.707 4.293a1 1 0 010 1.414L7.414 15H13a1 1 0 110 2H5a1 1 0 01-1-1V9a1 1 0 112 0v5.586l9.293-9.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
            </svg>
          </div>
          <div class="ml-3 text-sm font-normal">
            <%= notification.message %>
          </div>
          <button
            type="button"
            class="ml-auto -mx-1.5 -my-1.5 bg-white text-yellow-400 hover:text-yellow-900 rounded-lg focus:ring-2 focus:ring-gray-300 p-1.5 hover:bg-gray-100 inline-flex h-8 w-8 dark:text-gray-500 dark:hover:text-white dark:bg-gray-800 dark:hover:bg-gray-700"
            phx-click="remove_notification"
            data-id={notification.id}
            phx-target="#global-event-handler"
            phx-value-id={notification.id}
            aria-label="Close"
          >
            <span class="sr-only">Close</span>
            <svg aria-hidden="true" class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
            </svg>
          </button>
        </div>
      <% end %>
      </div>
    </span>
    """
  end
end
