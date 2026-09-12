# Remote Access

Tailscale is installed directly on the Mac mini. A remote device joins the
same Tailscale network and connects to host-published services using the host's
Tailscale name or address.

Tailscale authentication and device configuration are intentionally managed
outside this repository. No auth keys, node identities, account information,
or real tailnet names are included.

## Scope of the claim

The configuration demonstrates the remote-access path used by the operator.
It does not verify router port-forwarding, macOS firewall rules, Tailscale ACLs,
or whether another network path exists.

Compose bind addresses are configurable. Review those bindings together with
the host firewall and router configuration for each deployment.
