defmodule PeregrineQueueWeb.QueueController do
  use PeregrineQueueWeb, :controller
  alias PeregrineQueue.EnqueueService

  def enqueue(conn, %{"queue" => queue, "message" => message}) do
    {status, message} = EnqueueService.enqueue_job(queue, message)

    if status == :ok do
      conn
      |> put_status(:ok)
      |> json(%{status: "success", message: message})
    else
      conn
      |> put_status(:bad_request)
      |> json(%{status: "error", message: message})
    end

  end
end
