defmodule PeregrineQueueWeb.GRPCEndpoint do
  use GRPC.Endpoint
  intercept GRPC.Server.Interceptors.Logger
  # Run QueueService and add reflection
  run(PeregrineQueue.QueueServer)
  run(PeregrineQueue.QueueServer.Reflection)


end
