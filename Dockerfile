#See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
USER app
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["WebApplicationDemoSecurityScan.csproj", "."]
RUN dotnet restore "./WebApplicationDemoSecurityScan.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "./WebApplicationDemoSecurityScan.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./WebApplicationDemoSecurityScan.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# Run vulnerability scan on build image
FROM build AS vulnscan
COPY --from=aquasec/trivy:latest /usr/local/bin/trivy /usr/local/bin/trivy
RUN trivy rootfs --no-progress /
#

FROM base AS final
WORKDIR /app
# Non-root in action, configures the container to always run as app.
USER $APP_UID
#
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "WebApplicationDemoSecurityScan.dll"]



