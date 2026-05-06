#!/usr/bin/env bash
set -euo pipefail

version="${RUNNER_VERSION:-latest}"
output_dir="${RUNNER_OUTPUT_DIR:-runner-binaries}"
architectures="${RUNNER_ARCHITECTURES:-amd64 arm64}"

if [[ "${version}" == "latest" ]]; then
  version="$({
    python3 - <<'PY'
import json
import urllib.request

with urllib.request.urlopen("https://gitea.com/api/v1/repos/gitea/runner/releases/latest", timeout=60) as response:
    release = json.load(response)

print(release["tag_name"].removeprefix("v"))
PY
  })"
else
  version="${version#v}"
fi

if [[ -z "${version}" ]]; then
  echo "Unable to determine Gitea runner version" >&2
  exit 1
fi

mkdir -p "${output_dir}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

for arch in ${architectures}; do
  case "${arch}" in
    amd64|arm64) ;;
    *)
      echo "Unsupported architecture '${arch}'. Supported values: amd64 arm64" >&2
      exit 1
      ;;
  esac

  asset="gitea-runner-${version}-linux-${arch}.xz"
  base_url="https://gitea.com/gitea/runner/releases/download/v${version}"

  curl -fsSLo "${tmp_dir}/${asset}" "${base_url}/${asset}"
  curl -fsSLo "${tmp_dir}/${asset}.sha256" "${base_url}/${asset}.sha256"
  (cd "${tmp_dir}" && sha256sum -c "${asset}.sha256")

  xz -dc "${tmp_dir}/${asset}" > "${output_dir}/act_runner-linux-${arch}"
  chmod 0555 "${output_dir}/act_runner-linux-${arch}"
  echo "Downloaded ${output_dir}/act_runner-linux-${arch} from ${asset}"
done
