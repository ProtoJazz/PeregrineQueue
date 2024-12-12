defmodule PeregrineQueue.DateTimeFormatter do
  def format_datetime(nil), do: ""

  def format_datetime(%DateTime{} = datetime) do
    datetime
    |> DateTime.truncate(:second)
    |> to_string()
    |> String.replace("T", " ")
    |> String.replace("Z", " UTC")
  end

  def format_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _} ->
        datetime
        |> DateTime.truncate(:second)
        |> to_string()
        |> String.replace("T", " ")
        |> String.replace("Z", " UTC")

      {:error, _reason} ->
        "Invalid datetime"
    end
  end
end
