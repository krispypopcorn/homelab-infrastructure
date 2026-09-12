# Architecture

The environment combines host-installed services with two containerized
Compose projects.

## Host layer

- A Mac mini supplies compute and attached storage.
- OrbStack provides the Docker runtime and Docker Compose implementation.
- Tailscale runs on macOS and provides the remote-access path used away from
  the local network.
- Plex runs directly on macOS and remains outside Docker.

## Container layer

The Immich project contains the application server, PostgreSQL, Valkey, and a
machine-learning service. Compose places them on a project network. Only the
application server has a published host port; the database and cache do not.

Homepage runs as a separate Compose project. It reads Docker container state
through a read-only socket mount and reaches Immich and Plex using configured
host-reachable HTTP URLs. API credentials are injected through a private
environment file.

## Responsibility boundary

Immich, Plex, Homepage, PostgreSQL, Valkey, Tailscale, OrbStack, and Docker are
third-party software. This project covers their deployment configuration,
integration, validation, persistence, troubleshooting, and operation.

The repository is a sanitized subset of the live lab, not an export of its
runtime state or every private service.
