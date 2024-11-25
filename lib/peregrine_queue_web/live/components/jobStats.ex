defmodule PeregrineQueueWeb.Components.JobStats do
  use PeregrineQueueWeb, :html

  def job_stats(assigns) do
    ~H"""
    <div class="grid grid-cols-2 py-3">
      <dl>
        <dt class="text-base font-normal text-gray-500 dark:text-gray-400 pb-1">Successful</dt>
        <dd class="leading-none text-xl font-bold text-green-500 dark:text-green-400">
          <%= @jobs_stats.complete %>
        </dd>
      </dl>
      <dl>
        <dt class="text-base font-normal text-gray-500 dark:text-gray-400 pb-1">Active</dt>
        <dd class="leading-none text-xl font-bold text-yellow-500 dark:text-yellow-400">
          <%= @jobs_stats.active %>
        </dd>
      </dl>
      <dl>
        <dt class="text-base font-normal text-gray-500 dark:text-gray-400 pb-1">Pending</dt>
        <dd class="leading-none text-xl font-bold text-gray-500 dark:text-gray-400">
          <%= @jobs_stats.pending %>
        </dd>
      </dl>
      <dl>
        <dt class="text-base font-normal text-gray-500 dark:text-gray-400 pb-1">Failed</dt>
        <dd class="leading-none text-xl font-bold text-red-600 dark:text-red-500">
          <%= @jobs_stats.failed %>
        </dd>
      </dl>
    </div>
    """
  end
end
