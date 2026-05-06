#!/usr/bin/env sh
set -eu

if [ "$#" -eq 0 ]; then
  set -- daemon
fi

case "$1" in
  daemon|register|generate-config|exec|cache-server|--help|-h|--version|version|-*)
    set -- /home/gitea-runner/bin/act_runner "$@"
    ;;
esac

exec "$@"
