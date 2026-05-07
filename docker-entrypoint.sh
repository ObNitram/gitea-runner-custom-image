#!/usr/bin/env sh
set -eu
umask 0022

: "${CONFIG_FILE:?CONFIG_FILE is required}"
: "${GITEA_INSTANCE_URL:?GITEA_INSTANCE_URL is required}"
: "${GITEA_RUNNER_REGISTRATION_TOKEN:?GITEA_RUNNER_REGISTRATION_TOKEN is required}"

if [ "$#" -eq 0 ]; then
  set -- daemon
fi

case "$1" in
  daemon)
    if [ ! -f .runner ]; then
      act_runner register \
        --no-interactive \
        --instance "${GITEA_INSTANCE_URL}" \
        --token "${GITEA_RUNNER_REGISTRATION_TOKEN}" \
        --config "${CONFIG_FILE}"
    fi
    exec act_runner daemon --config "${CONFIG_FILE}"
    ;;
  register|generate-config|exec|cache-server|--help|-h|--version|version|-*)
    exec act_runner "$@"
    ;;
  *)
    exec "$@"
    ;;
esac
