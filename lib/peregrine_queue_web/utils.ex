defmodule PeregrineQueueWeb.Utils do

  def days_to_display_text(days_back) do
    case days_back do
      1 -> "Today"
      7 -> "Last 7 days"
      30 -> "Last 30 days"
      90 -> "Last 90 days"
      180 -> "Last 6 months"
      365 -> "Last year"
      _ -> "Custom"
    end
  end

end
