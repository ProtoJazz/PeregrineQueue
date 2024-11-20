# Build stage for Phoenix assets
FROM node:18-slim AS asset_builder
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy the entire project for context
COPY . .

# Build assets
WORKDIR /app/assets
RUN npm install
# Ensure directory exists
RUN mkdir -p ../priv/static/assets
# Run deploy script
RUN npm run deploy

# Build stage for Phoenix
FROM elixir:1.17.3-slim AS phoenix_builder
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set production environment
ENV MIX_ENV=prod
ENV PHX_SERVER=true

# First copy ALL project files to ensure static assets are in place
COPY . .

# Copy node_modules for JS bundling
COPY --from=asset_builder /app/assets/node_modules ./assets/node_modules

# Copy the compiled CSS/JS assets (this should NOT remove other static files)
COPY --from=asset_builder /app/priv/static/assets/* ./priv/static/assets/

# Install dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Build JS assets
RUN mix esbuild default --minify

# Compile and digest assets
RUN mix compile
RUN mix phx.digest
RUN mix release peregrine_queue

# Final stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libssl3 \
    postgresql-client \
    curl \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /app/priv/static/assets

# Copy the release and static assets
COPY --from=phoenix_builder /app/_build/prod/rel/peregrine_queue ./app
COPY --from=phoenix_builder /app/priv/static/assets /app/priv/static/assets

# Create a non-root user and set permissions
RUN useradd -m myapp && \
    chown -R myapp:myapp /app
USER myapp

# Set runtime environment variables
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