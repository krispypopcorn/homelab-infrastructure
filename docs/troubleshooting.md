# Troubleshooting

## Compose does not validate

- Confirm each `.env.example` was copied to `.env` beside its Compose file.
- Check that required variables are non-empty.
- Run `docker compose ... config` without `-q` for the validation message.

## A container is unhealthy or restarting

- Review `docker compose ... ps` and the affected container logs.
- Confirm PostgreSQL and Valkey are healthy before diagnosing the application.
- Verify bind-mounted directories exist and are writable by the configured
  container user.
- Confirm the host has sufficient free space.

## Homepage cannot reach a service

- Confirm the configured URL is reachable from inside the Homepage container.
- Check the service port, host binding, and allowed-host setting.
- Confirm the API token is valid without printing it to logs.
- Remember that `localhost` inside a container refers to that container.

## Remote access fails

- Confirm Tailscale is connected on both the Mac mini and remote device.
- Test the service locally before debugging the remote path.
- Review the host firewall, bind address, and Tailscale policy separately.

## Backup fails

- Confirm the Immich database container is running.
- Verify the configured database name and username.
- Check free space and permissions on the backup destination.
- Use `--skip-database` to isolate configuration archiving from database issues.
