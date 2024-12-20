import Config

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix assets.deploy` task,
# which you should run after static files are built and
# before starting your production server.
config :peregrine_queue, PeregrineQueueWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  check_origin: false

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: PeregrineQueue.Finch

# Do not print debug messages in production
config :logger, level: :info

config :peregrine_queue, PeregrineQueueWeb.GRPCEndpoint,
  ip: {0, 0, 0, 0},  # Bind to all interfaces
  port: 50051


# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
