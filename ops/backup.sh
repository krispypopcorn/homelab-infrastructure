#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${HOMELAB_ENV_FILE:-$ROOT_DIR/.env}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups}"
IMMICH_COMPOSE_FILE="${IMMICH_COMPOSE_FILE:-compose/immich/compose.yaml}"
IMMICH_DB_USERNAME="${IMMICH_DB_USERNAME:-immich}"
IMMICH_DB_NAME="${IMMICH_DB_NAME:-immich}"
STAMP="$(date -u +"%Y%m%d-%H%M%S")"
DRY_RUN=0
SKIP_DATABASE=0
PRUNE_DAYS=""
STAGING=""

usage() {
  cat <<'EOF'
Usage: ops/backup.sh [options]

Creates a private archive containing the public deployment configuration and,
by default, an Immich PostgreSQL logical dump. It does not copy photo or media
libraries and does not include populated .env files.

Options:
  --backup-dir PATH    Write the archive to PATH
  --skip-database     Back up configuration without a PostgreSQL dump
  --prune-days N      Delete matching archives older than N days
  --dry-run           Display the plan without writing files
  -h, --help          Show this help
EOF
}

log() {
  printf "%s\n" "$1"
}

die() {
  printf "[FAIL] %s\n" "$1" >&2
  exit 1
}

resolve_repo_path() {
  case "$1" in
    /*) printf "%s\n" "$1" ;;
    *) printf "%s/%s\n" "$ROOT_DIR" "${1#./}" ;;
  esac
}

cleanup() {
  if [[ -n "$STAGING" && -d "$STAGING" ]]; then
    rm -rf "$STAGING"
  fi
}

trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backup-dir)
      [[ $# -ge 2 ]] || die "--backup-dir requires a path"
      BACKUP_DIR="$2"
      shift 2
      ;;
    --skip-database)
      SKIP_DATABASE=1
      shift
      ;;
    --prune-days)
      [[ $# -ge 2 ]] || die "--prune-days requires a number"
      PRUNE_DAYS="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $1" ;;
  esac
done

if [[ -n "$PRUNE_DAYS" && ! "$PRUNE_DAYS" =~ ^[0-9]+$ ]]; then
  die "--prune-days must be a non-negative integer"
fi

BACKUP_DIR="$(resolve_repo_path "$BACKUP_DIR")"
IMMICH_COMPOSE_FILE="$(resolve_repo_path "$IMMICH_COMPOSE_FILE")"
ARCHIVE="$BACKUP_DIR/homelab-config-$STAMP.tar.gz"

CONFIG_PATHS=(
  README.md
  .gitignore
  .env.example
  compose/immich/compose.yaml
  compose/immich/.env.example
  compose/homepage/compose.yaml
  compose/homepage/.env.example
  config/homepage/bookmarks.yaml
  config/homepage/docker.yaml
  config/homepage/services.yaml
  config/homepage/settings.yaml
  config/homepage/widgets.yaml
  config/homepage/custom.css
  ops/README.md
  ops/status.sh
  ops/backup.sh
  scripts/storage-stats/update.sh
  scripts/storage-stats/com.example.homepage-storage-stats.plist.example
  scripts/storage-stats/README.md
  docs
)

log "Backup plan"
log "  destination: $ARCHIVE"
log "  configuration files: ${#CONFIG_PATHS[@]} entries"
if [[ "$SKIP_DATABASE" -eq 1 ]]; then
  log "  Immich database: skipped"
else
  log "  Immich database: logical dump"
fi
log "  photo and media files: excluded"
log "  populated environment files: excluded"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry run complete. No files were written."
  exit 0
fi

command -v docker >/dev/null 2>&1 || [[ "$SKIP_DATABASE" -eq 1 ]] \
  || die "docker is required for the database dump"
command -v tar >/dev/null 2>&1 || die "tar is required"

mkdir -p "$BACKUP_DIR"
STAGING="$(mktemp -d "$BACKUP_DIR/.homelab-config.XXXXXX")"
mkdir -p "$STAGING/configuration" "$STAGING/database"

for relative_path in "${CONFIG_PATHS[@]}"; do
  source_path="$ROOT_DIR/$relative_path"
  [[ -e "$source_path" ]] || die "Required configuration path is missing: $relative_path"
  mkdir -p "$STAGING/configuration/$(dirname "$relative_path")"
  cp -a "$source_path" "$STAGING/configuration/$relative_path"
done

if [[ "$SKIP_DATABASE" -eq 0 ]]; then
  [[ -f "$IMMICH_COMPOSE_FILE" ]] || die "Immich Compose file is missing"
  log "Creating Immich PostgreSQL logical dump..."
  docker compose -f "$IMMICH_COMPOSE_FILE" exec -T database \
    pg_dump -U "$IMMICH_DB_USERNAME" -d "$IMMICH_DB_NAME" --format=custom \
    > "$STAGING/database/immich-postgres.dump"
fi

cat > "$STAGING/README.txt" <<'EOF'
Private homelab configuration backup.

This archive contains deployment configuration and may contain an Immich
database dump. The database can include personal metadata. Keep the archive
private even though populated environment files and bulk media are excluded.
EOF

(cd "$STAGING" && find . -type f ! -name MANIFEST.txt ! -name SHA256SUMS.txt \
  -print | LC_ALL=C sort > MANIFEST.txt)

if command -v shasum >/dev/null 2>&1; then
  (cd "$STAGING" && while IFS= read -r file; do
    shasum -a 256 "$file"
  done < MANIFEST.txt > SHA256SUMS.txt)
elif command -v sha256sum >/dev/null 2>&1; then
  (cd "$STAGING" && while IFS= read -r file; do
    sha256sum "$file"
  done < MANIFEST.txt > SHA256SUMS.txt)
else
  die "shasum or sha256sum is required"
fi

tar -czf "$ARCHIVE" -C "$STAGING" .
chmod 600 "$ARCHIVE"

if [[ -n "$PRUNE_DAYS" ]]; then
  find "$BACKUP_DIR" -type f -name 'homelab-config-*.tar.gz' \
    -mtime +"$PRUNE_DAYS" -print -delete
fi

log "Backup complete: $ARCHIVE"
