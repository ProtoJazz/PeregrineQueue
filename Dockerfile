FROM rust:1.74 AS rust_builder
WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    && apt-get clean

COPY . .

WORKDIR /usr/src/app/example_workers/fast_response_rust_worker
RUN cargo build --release

FROM hexpm/elixir:1.15.8-erlang-26.2.5.4-ubuntu-focal-20240918 AS phoenix_builder
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive

RUN mix local.hex --force && mix local.rebar --force

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean


COPY mix.exs mix.lock ./
COPY config ./config
COPY lib ./lib
COPY priv ./priv
COPY assets ./assets

RUN mix deps.get --only prod
RUN MIX_ENV=prod mix compile
RUN npm --prefix ./assets install
RUN npm --prefix ./assets run deploy
RUN MIX_ENV=prod mix phx.digest
RUN MIX_ENV=prod mix release

FROM debian:bullseye-slim AS runtime
WORKDIR /app

RUN apt-get update && apt-get install -y \
    libssl-dev \
    && apt-get clean

COPY --from=phoenix_builder /app/_build/prod/rel/peregrine_queue ./

COPY --from=rust_builder /usr/src/app/example_workers/fast_response_rust_worker/target/release/fast_response_rust_worker /usr/local/bin/fast_response_rust_worker

ENV MIX_ENV=prod
ENV WORKER_ID=default_worker
ENV WORKER_ADDRESS=127.0.0.1:50053
ENV QUEUE_ADDRESS=http://localhost:50051
ENV QUEUE_NAME=media_update

EXPOSE 4000

CMD ["sh", "-c", "bin/peregrine_queue start & fast_response_rust_worker --worker-id=$WORKER_ID --worker-address=$WORKER_ADDRESS --queue-address=$QUEUE_ADDRESS --queue-name=$QUEUE_NAME"]