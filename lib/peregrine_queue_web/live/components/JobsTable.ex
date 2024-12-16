defmodule PeregrineQueueWeb.Components.JobsTable do
  use PeregrineQueueWeb, :html

  def paginated_table(assigns) do
    ~H"""
    <section class="bg-white dark:bg-gray-900">
      <div class="relative overflow-x-auto shadow-md sm:rounded-lg">
        <table class="w-full text-sm text-left rtl:text-right text-gray-500 dark:text-gray-400">
          <section class="flex items-center justify-between p-4 bg-white dark:bg-gray-800">
            <div class="inline-flex rounded-md shadow-sm" role="group">
              <button
                type="button"
                phx-click="retry_jobs"
                class="px-4 py-2 text-sm font-medium text-gray-900 bg-white border border-gray-200 rounded-s-lg hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:hover:text-white dark:hover:bg-gray-700 dark:focus:ring-blue-500 dark:focus:text-white"
              >
                Retry
              </button>

              <button
                type="button"
                phx-click="delete_jobs"
                class="px-4 py-2 text-sm font-medium text-gray-900 bg-white border border-gray-200 rounded-e-lg hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:hover:text-white dark:hover:bg-gray-700 dark:focus:ring-blue-500 dark:focus:text-white"
              >
                Delete
              </button>
            </div>
          </section>
          <thead class="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
            <tr>
              <th scope="col" class="p-4">
                <div class="flex items-center">
                  <input
                    id="checkbox-all-search"
                    type="checkbox"
                    phx-click="select_all_jobs"
                    class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 dark:focus:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
                    checked={@selected_jobs && Enum.count(@selected_jobs) > 0}
                  />
                  <label for="checkbox-all-search" class="sr-only">checkbox</label>
                </div>
              </th>
              <th scope="col" class="px-2 py-3">
                ID
              </th>
              <th scope="col" class="px-2 py-3">
                Attempts
              </th>
              <th scope="col" class="px-6 py-3">
                Next Attempt
              </th>
              <th scope="col" class="px-2 py-3">
                Status
              </th>
              <th scope="col" class="px-6 py-3">
                Payload
              </th>
              <th scope="col" class="px-6 py-3">
                Error
              </th>
              <th scope="col" class="px-3 py-3">
                Worker ID
              </th>
              <th scope="col" class="px-3 py-3">
                Worker Address
              </th>
              <th scope="col" class="px-6 py-3">
                Inserted At
              </th>
              <th scope="col" class="px-6 py-3">
                Updated At
              </th>
              <th scope="col" class="px-6 py-3">
                Actions
              </th>
            </tr>
          </thead>
          <tbody>
            <%= for job <- @jobs do %>
              <% error =
                if job.oban_job && List.last(job.oban_job.errors),
                  do: List.last(job.oban_job.errors)["error"],
                  else: "N/A" %>
              <% attempt = if job.oban_job, do: job.oban_job.attempt, else: "N/A" %>
              <% next_attempt = if job.oban_job, do: job.oban_job.scheduled_at, else: "N/A" %>
              <tr class="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600">
                <td class="w-4 p-4">
                  <div class="flex items-center">
                    <input
                      id={"checkbox-table-search-#{job.id}"}
                      type="checkbox"
                      phx-value-job-id={job.id}
                      phx-click="select_job"
                      checked={Enum.member?(@selected_jobs, job)}
                      class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 dark:focus:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
                    />
                    <label for="checkbox-table-search-1" class="sr-only">checkbox</label>
                  </div>
                </td>
                <th
                  scope="row"
                  class="px-2 py-4 font-medium text-gray-900 whitespace-nowrap dark:text-white"
                >
                  <%= live_patch to: ~p"/jobs/#{job.id}",
                    class: "flex items-center p-2 pl-11 w-full text-base font-medium text-gray-900 rounded-lg transition duration-75 group hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700" do %>
                    <%= job.id %>
                  <% end %>
                </th>
                <td class="px-2 py-2">
                  <%= attempt %>
                </td>
                <td class="px-6 py-4">
                  <%= next_attempt %>
                </td>
                <td class="px-2 py-4">
                  <%= job.status %>
                </td>
                <td class="px-6 py-4">
                  <%= job.payload %>
                </td>
                <td class="px-6 py-4">
                  <%= error %>
                </td>
                <td class="px-3 py-4">
                  <%= job.worker_id %>
                </td>
                <td class="px-3 py-4">
                  <%= job.worker_address %>
                </td>
                <td class="px-6 py-4">
                  <%= job.inserted_at %>
                </td>
                <td class="px-6 py-4">
                  <%= job.updated_at %>
                </td>

                <td class="px-6 py-4">
                  <a
                    href="#"
                    class="font-medium text-blue-600 dark:text-blue-500 hover:underline"
                    phx-click="retry_job"
                    phx-value-id={job.id}
                  >
                    Retry
                  </a>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
        <nav
          class="flex items-center flex-column flex-wrap md:flex-row justify-between pt-4"
          aria-label="Table navigation"
        >
          <span class="text-sm font-normal text-gray-500 dark:text-gray-400 mb-4 md:mb-0 block w-full md:inline md:w-auto">
            Showing
            <span class="font-semibold text-gray-900 dark:text-white">
              <%= (@meta.current_page - 1) * @meta.page_size + 1 %>-<%= min(
                @meta.current_page * @meta.page_size,
                @meta.total_count
              ) %>
            </span>
            of
            <span class="font-semibold text-gray-900 dark:text-white"><%= @meta.total_count %></span>
          </span>
          <!-- Pagination -->
          <ul class="inline-flex -space-x-px rtl:space-x-reverse text-sm h-8">
            <!-- Previous Button -->
            <li>
              <%= if @meta.has_previous_page? do %>
                <a
                  href="#"
                  phx-click="page"
                  phx-value-page={@meta.current_page - 1}
                  class="flex items-center justify-center px-3 h-8 ms-0 leading-tight rounded-s-lg text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
                >
                  Previous
                </a>
              <% else %>
                <a
                  href={nil}
                  class="flex items-center justify-center px-3 h-8 ms-0 leading-tight rounded-s-lg  cursor-not-allowed text-gray-300 bg-gray-200 border-gray-200 dark:bg-gray-700 dark:border-gray-600 dark:text-gray-500"
                >
                  Previous
                </a>
              <% end %>
            </li>
            <!-- Page Buttons -->
            <%= for page <- 1..@meta.total_pages do %>
              <li>
                <%= if page == @meta.current_page do %>
                  <a
                    href="#"
                    aria-current="page"
                    class="flex items-center justify-center px-3 h-8 text-blue-600 border border-gray-300 bg-blue-50 hover:bg-blue-100 hover:text-blue-700 dark:border-gray-700 dark:bg-gray-700 dark:text-white"
                  >
                    <%= page %>
                  </a>
                <% else %>
                  <a
                    href="#"
                    phx-click="page"
                    phx-value-page={page}
                    class="flex items-center justify-center px-3 h-8 leading-tight text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
                  >
                    <%= page %>
                  </a>
                <% end %>
              </li>
            <% end %>
            <!-- Next Button -->
            <li>
              <%= if @meta.has_next_page? do %>
                <a
                  href="#"
                  phx-click="page"
                  phx-value-page={@meta.current_page + 1}
                  class="flex items-center justify-center px-3 h-8 ms-0 leading-tight rounded-s-lg text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
                >
                  Next
                </a>
              <% else %>
                <a
                  href={nil}
                  class="flex items-center justify-center px-3 h-8 ms-0 leading-tight rounded-s-lg  cursor-not-allowed text-gray-300 bg-gray-200 border-gray-200 dark:bg-gray-700 dark:border-gray-600 dark:text-gray-500"
                >
                  Next
                </a>
              <% end %>
            </li>
          </ul>
        </nav>
      </div>
    </section>
    """
  end
end
