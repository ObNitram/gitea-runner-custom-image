# syntax=docker/dockerfile:1.7
FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    apt-get update; \
    apt-get upgrade -y;

RUN apt-get install -y ca-certificates openjdk-21-jdk

RUN apt-get install -y nodejs npm

RUN apt-get install -y \
    git \
    jq \
    curl \
    tar \
    xz-utils \
    findutils \
    unzip

RUN apt-get autoremove -y;

ENV RUNNER_HOME=/root \
    PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN install -d -m 0750 "${RUNNER_HOME}/data"

ARG TARGETARCH
ARG TARGETVARIANT

ARG YQ_VERSION=v4.45.1
RUN set -eux; \
    case "${TARGETARCH}" in \
    amd64) yq_arch=amd64 ;; \
    arm64) yq_arch=arm64 ;; \
    *) echo "Unsupported arch for yq: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${yq_arch}" -o /usr/local/bin/yq; \
    chmod 0555 /usr/local/bin/yq

COPY --chmod=0555 runner-binaries/act_runner-linux-${TARGETARCH} /usr/local/bin/act_runner
COPY --chmod=0555 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN set -eux; \
    case "${TARGETARCH}${TARGETVARIANT}" in \
    amd64|arm64*) ;; \
    *) echo "Unsupported architecture: TARGETARCH=${TARGETARCH} TARGETVARIANT=${TARGETVARIANT}" >&2; exit 1 ;; \
    esac

WORKDIR /root/data
VOLUME ["/root/data"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["daemon"]
