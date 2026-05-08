#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

COMPOSE_BASE=(-f deploy/compose/docker-compose.yaml)
if [[ -f ".runtime/docker-compose.override.yaml" ]]; then
  COMPOSE_BASE+=(-f .runtime/docker-compose.override.yaml)
fi

if [[ "${USE_LOCAL_NIM:-false}" == "true" ]]; then
  docker compose --env-file .env "${COMPOSE_BASE[@]}" --profile local-nim down
else
  docker compose --env-file .env "${COMPOSE_BASE[@]}" down
fi

echo "[ai-virtual-assistant] Stopped."
