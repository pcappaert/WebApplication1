# We use the "TFM" nomenclature here because the more readable DOTNET_VERSION causes a problem later on.  Specifically,
# in COPY command when building the runtime image, the TFM (target framework moniker) is added to the path.  However,
# that copy command is actually run side the runtime container image and the runtime container image defines an
# environment variable called DOTNET_VERSION.  Environment variables in the image take precedence over ARGs and that
# environment variable has the full semantic version (e.g., 6.0.9) which is not appropriate for the path expansion.
# Plus, for the pedants TFM is the more correct term anyways.
ARG DOTNET_TFM=6.0


FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_TFM} AS build

ARG ADO_TOKEN
ARG DOTNET_CONFIG=Release
ARG DOTNET_VERBOSITY_DEFAULT=minimal
ARG DOTNET_VERBOSITY_RESTORE=${DOTNET_VERBOSITY_DEFAULT}
ARG DOTNET_VERBOSITY_BUILD=${DOTNET_VERBOSITY_DEFAULT}
ARG DOTNET_VERBOSITY_PUBLISH=${DOTNET_VERBOSITY_DEFAULT}

WORKDIR /source

COPY . .

RUN dotnet restore --use-current-runtime --verbosity=${DOTNET_VERBOSITY_RESTORE}

RUN dotnet build --configuration ${DOTNET_CONFIG} --no-restore --no-incremental --use-current-runtime \
    --verbosity=normal

RUN dotnet publish --configuration ${DOTNET_CONFIG} --no-build \
    --verbosity=normal \
    WebApplication1/WebApplication1.csproj


FROM mcr.microsoft.com/dotnet/aspnet:${DOTNET_TFM}

ARG DOTNET_TFM=6.0
ARG DOTNET_CONFIG=Release

WORKDIR /app

COPY --from=build /source/WebApplication1/bin/${DOTNET_CONFIG}/net${DOTNET_TFM}/publish/ .

ENTRYPOINT ["dotnet", "WebApplication1.dll"]