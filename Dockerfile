# syntax=docker/dockerfile:1.7
FROM ubuntu:latest

ARG TARGETARCH
ARG TARGETVARIANT

ENV DEBIAN_FRONTEND=noninteractive \
    GITEA_RUNNER_HOME=/home/gitea-runner \
    PATH=/home/gitea-runner/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates; \
    groupadd --system --gid 10001 gitea-runner; \
    useradd --system --uid 10001 --gid gitea-runner --home-dir "${GITEA_RUNNER_HOME}" --create-home --shell /usr/sbin/nologin gitea-runner; \
    install -d -o gitea-runner -g gitea-runner -m 0750 "${GITEA_RUNNER_HOME}" "${GITEA_RUNNER_HOME}/data"; \
    install -d -o root -g root -m 0755 "${GITEA_RUNNER_HOME}/bin"; \
    rm -rf /var/lib/apt/lists/*; \
    find / -xdev -perm /6000 -type f -exec chmod a-s {} + || true

COPY --chmod=0555 runner-binaries/act_runner-linux-${TARGETARCH} /home/gitea-runner/bin/act_runner
COPY --chmod=0555 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN set -eux; \
    case "${TARGETARCH}${TARGETVARIANT}" in \
      amd64|arm64*) ;; \
      *) echo "Unsupported architecture: TARGETARCH=${TARGETARCH} TARGETVARIANT=${TARGETVARIANT}" >&2; exit 1 ;; \
    esac; \
    chown root:root "${GITEA_RUNNER_HOME}/bin/act_runner"; \
    ln -s "${GITEA_RUNNER_HOME}/bin/act_runner" /usr/local/bin/act_runner

USER 10001:10001
WORKDIR /home/gitea-runner/data
VOLUME ["/home/gitea-runner/data"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["daemon"]
