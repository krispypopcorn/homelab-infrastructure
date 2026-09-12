# Operations

Copy the root `.env.example` to `.env` before using these helpers.

## Status

`./ops/status.sh` validates both Compose files, checks running container state,
tests the Immich and Homepage HTTP endpoints, optionally checks Plex, and
verifies configured storage paths.

Set `PLEX_URL` to enable the Plex check or leave it blank to skip it.

## Backup

Preview the backup plan:

```bash
./ops/backup.sh --dry-run
```

Create a configuration and Immich database backup:

```bash
./ops/backup.sh --backup-dir ./backups
```

Create a configuration-only backup:

```bash
./ops/backup.sh --skip-database
```

Add `--prune-days 30` to remove matching archives older than 30 days. Pruning
is destructive and only targets files named `homelab-config-*.tar.gz` inside
the selected backup directory.

Archives are created with mode `600`. They remain private because an Immich
database dump can contain personal metadata. Store backups on separate media
and test restoration before relying on them.
