defmodule PeregrineQueueWeb.Router do
  use PeregrineQueueWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PeregrineQueueWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", PeregrineQueueWeb do
    pipe_through :api

    post "/enqueue", QueueController, :enqueue
    get "/health", HealthController, :check
  end

  scope "/", PeregrineQueueWeb do
    pipe_through :browser
    live "/", DashboardLive.Index, :index
    live "/queues/:name", QueueLive.Show, :show
    live "/jobs/:job_id", JobLive.Show, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", PeregrineQueueWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:peregrine_queue, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PeregrineQueueWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
