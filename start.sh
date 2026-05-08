#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

mkdir -p .runtime

if [[ ! -f ".env" ]]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

# shellcheck disable=SC1091
source .env

if [[ -z "${NVIDIA_API_KEY:-}" || "${NVIDIA_API_KEY}" == "your_nvidia_api_key_here" ]]; then
  echo "Error: NVIDIA_API_KEY is missing in .env"
  exit 1
fi
if [[ -z "${NGC_API_KEY:-}" || "${NGC_API_KEY}" == "your_ngc_api_key_here" ]]; then
  echo "Error: NGC_API_KEY is missing in .env"
  exit 1
fi

find_free_port() {
  local start_port="$1"
  python3 - "$start_port" <<'PY'
import socket, sys
p0=int(sys.argv[1])
for p in range(p0, 65535):
    s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    try:
        s.bind(("127.0.0.1", p))
        print(p)
        break
    except OSError:
        pass
    finally:
        s.close()
PY
}

UI_PORT="$(find_free_port 3001)"
API_GATEWAY_PORT="$(find_free_port 9000)"
PGADMIN_PORT="$(find_free_port 5050)"

cat > .runtime/docker-compose.override.yaml <<EOF
services:
  agent-frontend:
    ports:
      - "${UI_PORT}:3001"
  api-gateway-server:
    ports:
      - "${API_GATEWAY_PORT}:9000"
  pgadmin:
    ports:
      - "${PGADMIN_PORT}:80"
    volumes:
      - pgadmin_data:/var/lib/pgadmin
  postgres:
    volumes:
      - postgres_data:/var/lib/postgresql/data
  redis:
    volumes:
      - redis_data:/data
  etcd:
    volumes:
      - etcd_data:/etcd
  minio:
    volumes:
      - minio_data:/minio_data
  milvus:
    volumes:
      - milvus_data:/var/lib/milvus

volumes:
  postgres_data:
  pgadmin_data:
  redis_data:
  etcd_data:
  minio_data:
  milvus_data:
EOF

COMPOSE_BASE=(-f deploy/compose/docker-compose.yaml -f .runtime/docker-compose.override.yaml)
if [[ "${USE_CPU_MILVUS:-true}" == "true" ]]; then
  cat > .runtime/docker-compose.cpu.yaml <<EOF
services:
  milvus:
    image: milvusdb/milvus:v2.4.15
    deploy:
      resources:
        reservations:
          devices: []
EOF
  COMPOSE_BASE+=(-f .runtime/docker-compose.cpu.yaml)
fi

echo "${NGC_API_KEY}" | docker login nvcr.io -u '$oauthtoken' --password-stdin >/dev/null
echo "Docker login to nvcr.io succeeded."

# Rebuild mutable local services so a fresh pull can run without manual fixes.
docker compose --env-file .env "${COMPOSE_BASE[@]}" build agent-chain-server api-gateway-server

if [[ "${USE_LOCAL_NIM:-false}" == "true" ]]; then
  docker compose --env-file .env "${COMPOSE_BASE[@]}" --profile local-nim up -d --force-recreate
else
  docker compose --env-file .env "${COMPOSE_BASE[@]}" up -d --force-recreate
fi

cat > .runtime/ports.env <<EOF
UI_PORT=${UI_PORT}
API_GATEWAY_PORT=${API_GATEWAY_PORT}
PGADMIN_PORT=${PGADMIN_PORT}
EOF

echo "[ai-virtual-assistant] Started."
echo "[ai-virtual-assistant] UI: http://127.0.0.1:${UI_PORT}"
echo "[ai-virtual-assistant] API Gateway: http://127.0.0.1:${API_GATEWAY_PORT}"
echo "[ai-virtual-assistant] PgAdmin: http://127.0.0.1:${PGADMIN_PORT}"
echo "[ai-virtual-assistant] Logs: docker compose -f deploy/compose/docker-compose.yaml -f .runtime/docker-compose.override.yaml logs -f"
