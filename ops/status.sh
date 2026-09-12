#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${HOMELAB_ENV_FILE:-$ROOT_DIR/.env}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

STATUS_TIMEOUT="${STATUS_TIMEOUT:-5}"
IMMICH_COMPOSE_FILE="${IMMICH_COMPOSE_FILE:-compose/immich/compose.yaml}"
HOMEPAGE_COMPOSE_FILE="${HOMEPAGE_COMPOSE_FILE:-compose/homepage/compose.yaml}"
IMMICH_URL="${IMMICH_URL:-http://localhost:2283}"
HOMEPAGE_URL="${HOMEPAGE_URL:-http://localhost:3000}"
PLEX_URL="${PLEX_URL:-}"
CONFIG_STORAGE_PATH="${CONFIG_STORAGE_PATH:-$ROOT_DIR}"
PHOTO_STORAGE_PATH="${PHOTO_STORAGE_PATH:-}"

failures=0
warnings=0

section() {
  printf "\n== %s ==\n" "$1"
}

ok() {
  printf "[OK]   %s\n" "$1"
}

warn() {
  warnings=$((warnings + 1))
  printf "[WARN] %s\n" "$1"
}

fail() {
  failures=$((failures + 1))
  printf "[FAIL] %s\n" "$1"
}

resolve_repo_path() {
  case "$1" in
    /*) printf "%s\n" "$1" ;;
    *) printf "%s/%s\n" "$ROOT_DIR" "${1#./}" ;;
  esac
}

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "$1 is available"
  else
    fail "$1 is not available"
  fi
}

validate_compose() {
  local label="$1"
  local file
  file="$(resolve_repo_path "$2")"

  if [[ ! -f "$file" ]]; then
    fail "$label Compose file is missing: $file"
    return
  fi

  if docker compose -f "$file" config -q >/dev/null 2>&1; then
    ok "$label Compose configuration is valid"
  else
    fail "$label Compose configuration is invalid"
  fi
}

check_compose_state() {
  local label="$1"
  local file output service state health
  file="$(resolve_repo_path "$2")"

  if ! output="$(docker compose -f "$file" ps --all --format json 2>/dev/null)"; then
    fail "Could not query $label containers"
    return
  fi

  if [[ -z "$output" ]]; then
    fail "$label has no created containers"
    return
  fi

  if command -v jq >/dev/null 2>&1; then
    printf "%-28s %-10s %s\n" "SERVICE" "STATE" "HEALTH"
    while IFS=$'\t' read -r service state health; do
      [[ -n "$service" ]] || continue
      printf "%-28s %-10s %s\n" "$service" "$state" "$health"
      [[ "$state" == "running" ]] || fail "$label service is not running: $service"
      [[ "$health" != "unhealthy" ]] || fail "$label service is unhealthy: $service"
    done < <(printf "%s\n" "$output" | jq -r '
      if type == "array" then .[] else . end
      | [.Service, .State, (if .Health == "" then "not-defined" else .Health end)]
      | @tsv
    ')
  else
    docker compose -f "$file" ps --all
    warn "jq is unavailable; container state was displayed but not evaluated"
  fi
}

check_http() {
  local label="$1"
  local url="$2"
  local code

  [[ -n "$url" ]] || return
  code="$(curl --silent --show-error --max-time "$STATUS_TIMEOUT" \
    --output /dev/null --write-out '%{http_code}' "$url" 2>/dev/null || true)"

  case "$code" in
    2*|3*|401|403) ok "$label is reachable ($code)" ;;
    000|"") fail "$label is not reachable" ;;
    *) warn "$label returned HTTP $code" ;;
  esac
}

check_path() {
  local label="$1"
  local path="$2"
  [[ -n "$path" ]] || return

  if [[ -e "$path" ]]; then
    ok "$label exists"
    df -h "$path" 2>/dev/null | awk 'NR == 2 {print "       " $2 " total, " $4 " free, " $5 " used"}'
  else
    fail "$label is missing: $path"
  fi
}

section "Tools"
check_command docker
check_command curl

section "Compose validation"
validate_compose "Immich" "$IMMICH_COMPOSE_FILE"
validate_compose "Homepage" "$HOMEPAGE_COMPOSE_FILE"

section "Container state"
if docker info >/dev/null 2>&1; then
  check_compose_state "Immich" "$IMMICH_COMPOSE_FILE"
  check_compose_state "Homepage" "$HOMEPAGE_COMPOSE_FILE"
else
  fail "Docker daemon is unavailable"
fi

section "HTTP reachability"
if command -v curl >/dev/null 2>&1; then
  check_http "Immich" "$IMMICH_URL/api/server/ping"
  check_http "Homepage" "$HOMEPAGE_URL"
  if [[ -n "$PLEX_URL" ]]; then
    check_http "Plex" "$PLEX_URL/identity"
  else
    warn "PLEX_URL is unset; optional Plex check skipped"
  fi
fi

section "Storage"
check_path "Configuration storage" "$(resolve_repo_path "$CONFIG_STORAGE_PATH")"
if [[ -n "$PHOTO_STORAGE_PATH" ]]; then
  check_path "Photo storage" "$(resolve_repo_path "$PHOTO_STORAGE_PATH")"
else
  warn "PHOTO_STORAGE_PATH is unset; photo-storage check skipped"
fi

section "Summary"
printf "Failures: %s\nWarnings: %s\n" "$failures" "$warnings"

[[ "$failures" -eq 0 ]]
