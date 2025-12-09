FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY EFMigrationDemo.csproj ./
RUN dotnet restore EFMigrationDemo.csproj

COPY . .

RUN dotnet publish EFMigrationDemo.csproj --configuration Release --output /app/publish /p:UseAppHost=false

RUN  <<EOT
    dotnet new tool-manifest &&
    dotnet tool install --global dotnet-ef --version 8.*
EOT

ENV PATH="${PATH}:/root/.dotnet/tools"

## See: https://learn.microsoft.com/en-us/dotnet/core/rid-catalog
RUN <<EOT
    OS=$(uname -s | tr '[:upper:]' '[:lower:]') &&
    ARCH=$(uname -m) &&
    if [ "${ARCH}" = "amd64" ]; then ARCH="x64" ; fi &&
    if [ "${ARCH}" = "aarch64" ]; then ARCH="arm64" ; fi &&
    RUNTIME="${OS}-${ARCH}" &&
    dotnet build EFMigrationDemo.csproj --configuration Release &&
    dotnet ef migrations bundle --self-contained --target-runtime "${RUNTIME}" --output /app/efbundle
EOT

FROM mcr.microsoft.com/dotnet/runtime-deps:8.0 AS migrator
WORKDIR /app
COPY --from=build /app/efbundle .
ENTRYPOINT ["./efbundle"]

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS app
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "EFMigrationDemo.dll"]
