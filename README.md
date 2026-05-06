# gitea-runner-custom-image

Custom Docker image for running the Gitea runner as an unprivileged `gitea-runner` user.

## Contents

- Base image: `ubuntu:latest`.
- System packages are upgraded during the image build with `apt-get upgrade` so the image starts from current Ubuntu packages.
- Installs `git`, `nodejs`, `npm`, and the highest-versioned `openjdk-*-jdk` package available from the `ubuntu:latest` APT repositories.
- Keeps package installation, user creation, and runner binary copy in separate Docker layers to improve build cache reuse.
- Downloads the latest Linux binary published by `gitea/runner` outside `docker build` with `scripts/download-gitea-runner.sh`, then copies it into the image with `COPY`.
- Automatically selects the pre-downloaded `amd64` or `arm64` binary through BuildKit (`TARGETARCH`).
- Verifies the SHA-256 checksum provided by the Gitea release before the binary is copied into the image.
- Runs by default as the non-root `gitea-runner` user (`UID/GID 10001`).
- Installs the runner binary at `/home/gitea-runner/bin/act_runner`.
- Uses `/home/gitea-runner/data` as the working directory and data volume to make read-only root filesystem deployments easier.

## Local build

Download the binaries into the Docker build context first:

```bash
./scripts/download-gitea-runner.sh
```

Then build the multi-architecture image:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t gitea-runner-custom:latest .
```

To pin a specific runner version during the download step:

```bash
RUNNER_VERSION=v1.0.0 ./scripts/download-gitea-runner.sh
docker buildx build --platform linux/amd64,linux/arm64 -t gitea-runner-custom:1.0.0 .
```

## Runtime

By default, the container runs:

```bash
/home/gitea-runner/bin/act_runner daemon
```

Example hardened runtime command:

```bash
docker run --rm \
  --read-only \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  -v gitea-runner-data:/home/gitea-runner/data \
  gitea-runner-custom:latest
```

> The Gitea runner may need additional access depending on the configured executor, such as a Docker socket or a compatible container engine. Add those permissions only when needed.

## GitHub Actions

The workflow `.github/workflows/build-image.yml` downloads the `amd64` and `arm64` binaries before the Docker build, then builds and always pushes the multi-architecture `linux/amd64` and `linux/arm64` image to GHCR from `ubuntu-latest`.

- Pull requests, branches, tags, and manual runs: build and push to `ghcr.io/<owner>/gitea-runner-custom`.
