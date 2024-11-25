defmodule PeregrineQueueWeb.Components.JobsChart do
  use PeregrineQueueWeb, :html

  def jobs_chart(assigns) do
    ~H"""
    <div phx-hook="DashboardChart" id="bar-chart"></div>
    <div class="grid grid-cols-1 items-center border-gray-200 border-t dark:border-gray-700 justify-between">
      <div class="flex justify-between items-center pt-5">
        <!-- Button -->
        <button
          id="dropdownDefaultButton"
          data-dropdown-toggle="lastDaysdropdown"
          data-dropdown-placement="bottom"
          class="text-sm font-medium text-gray-500 dark:text-gray-400 hover:text-gray-900 text-center inline-flex items-center dark:hover:text-white"
          type="button"
        >
          <%= PeregrineQueueWeb.Utils.days_to_display_text(@days_back) %>
          <svg
            class="w-2.5 m-2.5 ms-1.5"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 10 6"
          >
            <path
              stroke="currentColor"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="m1 1 4 4 4-4"
            />
          </svg>
        </button>
        <!-- Dropdown menu -->
        <div
          id="lastDaysdropdown"
          class="z-10 hidden bg-white divide-y divide-gray-100 rounded-lg shadow w-44 dark:bg-gray-700"
        >
          <ul
            class="py-2 text-sm text-gray-700 dark:text-gray-200"
            aria-labelledby="dropdownDefaultButton"
          >
            <li>
              <a
                href="#"
                phx-click="range_adjust"
                phx-value-days_back="1"
                class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
              >
                Today
              </a>
            </li>
            <li>
              <a
                href="#"
                phx-click="range_adjust"
                phx-value-days_back="7"
                class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
              >
                Last 7 days
              </a>
            </li>
            <li>
              <a
                href="#"
                phx-click="range_adjust"
                phx-value-days_back="30"
                class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
              >
                Last 30 days
              </a>
            </li>
            <li>
              <a
                href="#"
                phx-click="range_adjust"
                phx-value-days_back="90"
                class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
              >
                Last 90 days
              </a>
            </li>
            <li>
              <a
                href="#"
                phx-click="range_adjust"
                phx-value-days_back="180"
                class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
              >
                Last 6 months
              </a>
            </li>
            <li>
              <a
                href="#"
                phx-click="range_adjust"
                phx-value-days_back="365"
                class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
              >
                Last year
              </a>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end
end
