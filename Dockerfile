# Build stage for Phoenix assets
FROM rust:1.75 as rust_builder

WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    curl \
    && apt-get clean

COPY . .

WORKDIR /usr/src/app/example_workers/fast_response_rust_worker

RUN cargo build

RUN cp target/debug/fast_response_rust_worker /usr/local/bin/


FROM node:18-slim AS asset_builder
WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    python3 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY . .

WORKDIR /app/assets
RUN npm install
RUN mkdir -p ../priv/static/assets
RUN npm run deploy

# Build stage for Phoenix
FROM elixir:1.17.3-slim AS phoenix_builder
WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod
ENV PHX_SERVER=true

COPY . .

COPY --from=asset_builder /app/assets/node_modules ./assets/node_modules

COPY --from=asset_builder /app/priv/static/assets/* ./priv/static/assets/

RUN mix deps.get --only prod
RUN mix deps.compile

RUN mix esbuild default --minify

RUN mix compile
RUN mix phx.digest
RUN mix release peregrine_queue

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    libssl3 \
    postgresql-client \
    curl \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/priv/static/assets

COPY --from=phoenix_builder /app/_build/prod/rel/peregrine_queue ./app
COPY --from=phoenix_builder /app/priv/static/assets /app/priv/static/assets
COPY --from=rust_builder /usr/src/app/example_workers/fast_response_rust_worker/target/debug/fast_response_rust_worker /usr/local/bin/fast_response_rust_worker


RUN useradd -m myapp && \
    chown -R myapp:myapp /app
USER myapp

ENV PHX_SERVER=true
ENV WORKER_ID=prod_worker
ENV WORKER_ADDRESS=0.0.0.0:50053
ENV PORT=8080
ENV PHOENIX_INTERNAL_PORT=50051
ENV QUEUE_CONFIG='{"push_queues":[{"name":"media_update","concurrency":20,"rate_limit":10, "rate_window": 60000},{"name":"image_processing","concurrency":10,"rate_limit":10, "rate_window": 60000},{"name":"data_sync","concurrency":5,"rate_limit":5, "rate_window": 60000}],"pull_queues":[{"name":"web_scrapping","concurrency":10,"rate_limit":5, "rate_window": 60000}]}'

# Expose ports
EXPOSE 8080
EXPOSE 50051
EXPOSE 50053

# Start command
CMD ["sh", "-c", "/app/bin/peregrine_queue eval \"PeregrineQueue.Release.migrate\" && /app/bin/peregrine_queue start"]