# Security and Privacy

This repository is designed to publish configuration patterns without
publishing the operator's data or identity.

## Excluded material

- Populated environment files and API credentials
- Real hostnames, addresses, usernames, and filesystem paths
- Photos, videos, media libraries, thumbnails, and metadata
- PostgreSQL and application database files
- Logs, caches, session data, certificates, and private keys
- Backup archives and dashboard artwork
- Tailscale account, device, and authentication state

Example passwords and tokens are deliberately blank. Generate local values and
store them only in ignored `.env` files or an appropriate secret store.

## Operational considerations

- Published host ports can be reachable through more than one host interface.
  Tailscale usage does not by itself verify firewall or router policy.
- The Homepage Docker socket mount is read-only, but access to the Docker API
  still exposes operational metadata. Remove it if container status is not
  required.
- A PostgreSQL logical dump may contain personal photo metadata even when bulk
  files are excluded. Backup archives are created with mode `600` and must
  remain private.
- Before publication, validate the exact staged file list and run both a secret
  scan and targeted searches for identifying values.
