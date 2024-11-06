defmodule PeregrineQueueWeb.GRPCEndpoint do
  use GRPC.Endpoint
  intercept GRPC.Server.Interceptors.Logger
  # Run QueueService and add reflection
  run(PeregrineQueue.QueueService)
  run(PeregrineQueue.QueueService.Reflection)
end
