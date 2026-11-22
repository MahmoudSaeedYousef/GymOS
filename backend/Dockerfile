# Stage 1: Restore & Build
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# نسخ ملفات المشاريع من مسارها المباشر داخل backend
COPY ["GymOS.Domain/GymOS.Domain.csproj", "GymOS.Domain/"]
COPY ["GymOS.Application/GymOS.Application.csproj", "GymOS.Application/"]
COPY ["GymOS.Infrastructure/GymOS.Infrastructure.csproj", "GymOS.Infrastructure/"]
COPY ["GymOS.Api/GymOS.Api.csproj", "GymOS.Api/"]

RUN dotnet restore "GymOS.Api/GymOS.Api.csproj"

# نسخ باقي الكود وعمل Publish
COPY . .
WORKDIR "/src/GymOS.Api"
RUN dotnet publish "GymOS.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

COPY --from=build /app/publish .
RUN mkdir -p /app/wwwroot/uploads
USER app

ENTRYPOINT ["dotnet", "GymOS.Api.dll"]