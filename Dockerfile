# syntax=docker/dockerfile:1.7
FROM ubuntu:latest

ARG TARGETARCH
ARG TARGETVARIANT
ARG RUNNER_VERSION=latest

ENV DEBIAN_FRONTEND=noninteractive \
    GITEA_RUNNER_HOME=/home/gitea-runner \
    PATH=/home/gitea-runner/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl xz-utils; \
    groupadd --system --gid 10001 gitea-runner; \
    useradd --system --uid 10001 --gid gitea-runner --home-dir "${GITEA_RUNNER_HOME}" --create-home --shell /usr/sbin/nologin gitea-runner; \
    install -d -o gitea-runner -g gitea-runner -m 0750 "${GITEA_RUNNER_HOME}" "${GITEA_RUNNER_HOME}/data"; \
    install -d -o root -g root -m 0755 "${GITEA_RUNNER_HOME}/bin"; \
    build_arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "${build_arch}${TARGETVARIANT}" in \
      amd64) runner_arch="amd64" ;; \
      arm64*) runner_arch="arm64" ;; \
      *) echo "Unsupported architecture: TARGETARCH=${TARGETARCH} TARGETVARIANT=${TARGETVARIANT} detected=${build_arch}" >&2; exit 1 ;; \
    esac; \
    if [[ "${RUNNER_VERSION}" == "latest" ]]; then \
      release_api="https://gitea.com/api/v1/repos/gitea/runner/releases/latest"; \
      release_json="$(curl -fsSL "${release_api}")"; \
      runner_version="$(printf '%s' "${release_json}" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\{0,1\}\([^"]*\)".*/\1/p')"; \
    else \
      runner_version="${RUNNER_VERSION#v}"; \
    fi; \
    test -n "${runner_version}"; \
    asset="gitea-runner-${runner_version}-linux-${runner_arch}.xz"; \
    base_url="https://gitea.com/gitea/runner/releases/download/v${runner_version}"; \
    curl -fsSLo "/tmp/${asset}" "${base_url}/${asset}"; \
    curl -fsSLo "/tmp/${asset}.sha256" "${base_url}/${asset}.sha256"; \
    (cd /tmp && sha256sum -c "${asset}.sha256"); \
    xz -dc "/tmp/${asset}" > "${GITEA_RUNNER_HOME}/bin/act_runner"; \
    chmod 0555 "${GITEA_RUNNER_HOME}/bin/act_runner"; \
    chown root:root "${GITEA_RUNNER_HOME}/bin/act_runner"; \
    ln -s "${GITEA_RUNNER_HOME}/bin/act_runner" /usr/local/bin/act_runner; \
    apt-get purge -y --auto-remove curl xz-utils; \
    rm -rf /var/lib/apt/lists/* /tmp/*; \
    find / -xdev -perm /6000 -type f -exec chmod a-s {} + || true

COPY --chmod=0555 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

USER 10001:10001
WORKDIR /home/gitea-runner/data
VOLUME ["/home/gitea-runner/data"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["daemon"]
