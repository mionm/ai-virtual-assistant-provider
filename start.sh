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
  python3 - "$start_port" 6050 "${USED_PORTS:-}" <<'PY'
import socket, sys
p0=int(sys.argv[1])
max_port=int(sys.argv[2])
used={int(p) for p in sys.argv[3].split(",") if p}
for p in range(p0, max_port + 1):
    if p in used:
        continue
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

reserve_port() {
  local var_name="$1"
  local default_port="$2"
  local current_port="${!var_name:-$default_port}"

  if [[ ! "$current_port" =~ ^[0-9]+$ || "$current_port" -lt 6000 || "$current_port" -gt 6050 ]]; then
    current_port="$default_port"
  fi

  local resolved_port
  resolved_port="$(find_free_port "$current_port")"
  if [[ -z "$resolved_port" ]]; then
    echo "Error: no free port available in AI Hub range 6000-6050 for ${var_name}" >&2
    exit 1
  fi

  export "${var_name}=${resolved_port}"
  if [[ -n "${USED_PORTS:-}" ]]; then
    USED_PORTS="${USED_PORTS},${resolved_port}"
  else
    USED_PORTS="${resolved_port}"
  fi
}

USED_PORTS=""
reserve_port UI_PORT 6000
reserve_port API_GATEWAY_PORT 6001
reserve_port AGENT_CHAIN_PORT 6002
reserve_port ANALYTICS_PORT 6003
reserve_port UNSTRUCTURED_RETRIEVER_PORT 6004
reserve_port STRUCTURED_RETRIEVER_PORT 6005
reserve_port POSTGRES_PORT 6006
reserve_port REDIS_PORT 6007
reserve_port REDIS_COMMANDER_PORT 6008
reserve_port MINIO_PORT 6009
reserve_port MINIO_CONSOLE_PORT 6010
reserve_port MILVUS_PORT 6011
reserve_port MILVUS_HEALTH_PORT 6012
reserve_port PGADMIN_PORT 6013

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
AGENT_CHAIN_PORT=${AGENT_CHAIN_PORT}
ANALYTICS_PORT=${ANALYTICS_PORT}
UNSTRUCTURED_RETRIEVER_PORT=${UNSTRUCTURED_RETRIEVER_PORT}
STRUCTURED_RETRIEVER_PORT=${STRUCTURED_RETRIEVER_PORT}
POSTGRES_PORT=${POSTGRES_PORT}
REDIS_PORT=${REDIS_PORT}
REDIS_COMMANDER_PORT=${REDIS_COMMANDER_PORT}
MINIO_PORT=${MINIO_PORT}
MINIO_CONSOLE_PORT=${MINIO_CONSOLE_PORT}
MILVUS_PORT=${MILVUS_PORT}
MILVUS_HEALTH_PORT=${MILVUS_HEALTH_PORT}
PGADMIN_PORT=${PGADMIN_PORT}
EOF

echo "[ai-virtual-assistant] Started."
echo "[ai-virtual-assistant] UI: http://127.0.0.1:${UI_PORT}"
echo "[ai-virtual-assistant] API Gateway: http://127.0.0.1:${API_GATEWAY_PORT}"
echo "[ai-virtual-assistant] PgAdmin: http://127.0.0.1:${PGADMIN_PORT}"
echo "[ai-virtual-assistant] Ports saved to .runtime/ports.env"
echo "[ai-virtual-assistant] Logs: docker compose -f deploy/compose/docker-compose.yaml -f .runtime/docker-compose.override.yaml logs -f"
