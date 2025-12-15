# syntax=docker/dockerfile:1
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

ENV PATH="${PATH}:/root/.dotnet/tools"
RUN dotnet tool install --global dotnet-ef --version 8.*
WORKDIR /src

COPY EFMigrationDemo.csproj ./

RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages <<EOT
    dotnet restore EFMigrationDemo.csproj
EOT

COPY . .

RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages <<EOT
    dotnet build EFMigrationDemo.csproj \
        --no-restore \
        --configuration Release
EOT

# See: https://learn.microsoft.com/en-us/dotnet/core/rid-catalog
RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages <<EOT
    OS=$(uname -s | tr '[:upper:]' '[:lower:]') &&
    ARCH=$(uname -m) &&
    if [ "${ARCH}" = "amd64" ] || [ "${ARCH}" = "x86_64" ]; then ARCH="x64"; fi &&
    if [ "${ARCH}" = "aarch64" ]; then ARCH="arm64"; fi &&
    RUNTIME="${OS}-${ARCH}" &&
    dotnet ef migrations bundle \
        --self-contained \
        --no-build \
        --configuration Release \
        --target-runtime "${RUNTIME}" \
        --project EFMigrationDemo.csproj \
        --output /efbundle
EOT

FROM mcr.microsoft.com/dotnet/runtime-deps:8.0 AS runtime
WORKDIR /app
COPY --from=build /efbundle .
RUN chmod +x ./efbundle

RUN <<EOT
cat <<'EOF' > /app/start.sh
#!/usr/bin/env bash

set -o nounset -o errexit -o pipefail

DB_CONNECTION_STRING="${DB_CONNECTION_STRING:-}"

if [ -z "${DB_CONNECTION_STRING}" ]; then
    echo "error: DB_CONNECTION_STRING is required but missing" >&2
    exit 1
fi

exec /app/efbundle --connection "${DB_CONNECTION_STRING}" "${@}"
EOF
EOT

RUN chmod +x /app/start.sh

ENTRYPOINT ["/app/start.sh"]

# FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS app
# WORKDIR /app
# COPY --from=build /app/publish .
# ENTRYPOINT ["dotnet", "EFMigrationDemo.dll"]
