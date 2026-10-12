# Build from the project root with:
# docker build -f yourname_server/Dockerfile .

# Build stage
FROM dart:3.12.0 AS build

# Create a minimal workspace that preserves locked server dependency versions.
WORKDIR /app
COPY pubspec.lock .
COPY yourname_server/pubspec.yaml yourname_server/pubspec.yaml
RUN printf '%s\n' \
  'name: _' \
  'environment:' \
  '  sdk: ^3.8.0' \
  'workspace:' \
  '  - yourname_server' \
  > pubspec.yaml
RUN dart pub get

COPY yourname_server/lib yourname_server/lib
COPY yourname_server/bin yourname_server/bin
COPY yourname_server/config/production.yaml yourname_server/config/production.yaml
COPY yourname_server/web yourname_server/web
COPY yourname_server/migrations yourname_server/migrations

# Compile the server executable.
WORKDIR /app/yourname_server
RUN dart compile exe bin/main.dart -o bin/server

# Add a fallback for the copy of possibly missing directories.
RUN mkdir -p config web migrations

# Final stage
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app

# Environment variables
ENV runmode=production
ENV serverid=default
ENV logging=normal
ENV role=monolith

# Copy runtime dependencies
COPY --from=build /runtime/ /

# Copy compiled server executable
COPY --from=build /app/yourname_server/bin/server server

# Copy configuration files and resources
COPY --from=build /app/yourname_server/config/ config/
COPY --from=build /app/yourname_server/web/ web/
COPY --from=build /app/yourname_server/migrations/ migrations/

# This file is required to enable the endpoint log filter in Insights.
COPY --from=build /app/yourname_server/lib/src/generated/protocol.yaml lib/src/generated/protocol.yaml

# Expose ports
EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

# Define the entrypoint command
ENTRYPOINT ["./server", "--mode=production"]
