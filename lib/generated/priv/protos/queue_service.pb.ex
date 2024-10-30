defmodule Queue.RegisterWorkerRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3

  field :queue_name, 1, type: :string, json_name: "queueName"
  field :worker_id, 2, type: :string, json_name: "workerId"
  field :worker_address, 3, type: :string, json_name: "workerAddress"
end

defmodule Queue.RegisterWorkerResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3

  field :status, 1, type: :string
  field :message, 2, type: :string
end

defmodule Queue.QueueService.Service do
  @moduledoc false

  use GRPC.Service, name: "queue.QueueService", protoc_gen_elixir_version: "0.13.0"

  rpc(:RegisterWorker, Queue.RegisterWorkerRequest, Queue.RegisterWorkerResponse)
end

defmodule Queue.QueueService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Queue.QueueService.Service
end
