# Operations

## Validate configuration

```bash
docker compose -f compose/immich/compose.yaml config -q
docker compose -f compose/homepage/compose.yaml config -q
bash -n ops/status.sh ops/backup.sh
zsh -n scripts/storage-stats/update.sh
```

## Start and inspect

```bash
docker compose -f compose/immich/compose.yaml up -d
docker compose -f compose/homepage/compose.yaml up -d
docker compose -f compose/immich/compose.yaml ps
docker compose -f compose/homepage/compose.yaml ps
./ops/status.sh
```

## Stop

```bash
docker compose -f compose/homepage/compose.yaml down
docker compose -f compose/immich/compose.yaml down
```

`down` removes project containers and networks but does not remove bind-mounted
data or the named machine-learning cache unless volume removal is explicitly
requested.

## Back up

Run `./ops/backup.sh --dry-run` first. The default backup includes public
configuration plus an Immich PostgreSQL logical dump. It excludes populated
environment files and bulk photo/media storage.

The logical dump can still contain personal metadata. Treat the archive as
private, store a copy on separate media, and test restoration periodically.

## Updates

Review upstream release notes and configuration changes before changing image
versions. Validate Compose after each change and confirm database, cache,
machine-learning, HTTP, and storage health after the containers restart.
