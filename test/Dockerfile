# Isolated environment for running the plugin test suite.
#
# The suite installs tools, writes to the mise data directory, and depends on
# mise settings such as `prereleases`. Running it against a real workstation
# both pollutes that setup and lets local settings mask failures — a snapshot
# bug went unnoticed for exactly that reason, because the dev machine had
# `prereleases = true` while CI did not.
#
# Build and run via `mise run test-container`.

FROM debian:trixie-slim

# ca-certificates is required before anything can fetch over HTTPS.
# python3 runs the jdtls launcher; a JRE runs the server itself.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        openjdk-21-jre-headless \
        python3 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://mise.run | sh
ENV PATH="/root/.local/bin:${PATH}"

# Archives are 50-180MB; keeping them makes repeat runs offline.
ENV MISE_ALWAYS_KEEP_DOWNLOAD=1
ENV MISE_TRUSTED_CONFIG_PATHS=/src

# Deliberately left at its default. Enabling it here would hide exactly the
# class of bug this container exists to catch.
# ENV MISE_PRERELEASES=1

WORKDIR /src
CMD ["./mise-tasks/test"]
