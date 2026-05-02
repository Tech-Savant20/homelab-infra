# Vault-Server — Architecture Reference

Vaultwarden + External Monitoring · Oracle Cloud (Always Free)

> Sanitized reference — see private copy for real IPs/credentials.

## 1. Network Identity

| | |
|---|---|
| Instance shape | VM.Standard.E2.1.Micro (AMD, Always Free) — 1 OCPU, 1GB RAM |
| OS | Ubuntu 24.04 |
| Public IP | `<VAULT_SERVER_PUBLIC_IP>` |
| Tailscale IP | `<VAULT_SERVER_TAILSCALE_IP>` |
| Domain | `<VAULT_DUCKDNS_DOMAIN>` |

This is a deliberately small, isolated instance — separate from the Minecraft server — so the password manager's availability and security don't depend on, or get affected by, anything else running.

## 2. Architecture

```
Internet → Caddy (80/443, auto TLS via Let's Encrypt) → Vaultwarden (127.0.0.1:8080, internal only)
```

Vaultwarden is bound to `127.0.0.1` only — never directly reachable from outside the box. Caddy is the sole public entry point, handling TLS termination and reverse-proxying internally. This was a deliberate hardening change made after the initial deployment (which briefly bound Vaultwarden directly to a public port before Caddy was introduced).

See [`vault-server/Caddyfile`](../vault-server/Caddyfile).

## 3. Data Migration & Backup

Vaultwarden was migrated from an existing instance running on the home server (see the Jarvis reference), which was then fully retired — this vault-server is now the single source of truth for stored credentials.

A daily cron job (`backup-vaultwarden.sh`, see [`vault-server/scripts/`](../vault-server/scripts/)) tars the Vaultwarden data directory and pushes it, over Tailscale via `scp`, to the home server — keeping the last 7 backups. This is the critical redundancy layer: since the original copy was retired, this backup is the only protection against data loss on this single small instance.

## 4. Monitoring

Runs its own Uptime Kuma instance, which is one leg of a three-way cross-monitoring setup (see the Jarvis reference for the full picture): this instance watches the home server and the Minecraft server, while the home server's own Uptime Kuma watches this instance and the Minecraft server in return. Email alerts are sent via Gmail SMTP to a filtered alias address.

## 5. Networking & Security

| Port | Purpose | Exposure |
|---|---|---|
| 22 | SSH | Public |
| 80 | HTTP (Let's Encrypt ACME challenge, redirects to HTTPS) | Public |
| 443 | HTTPS (Vaultwarden via Caddy) | Public |
| 3001 | Uptime Kuma | Public |
| 61208 | Glances (metrics) | Restricted to the home server's Tailscale IP |

## 7. Notable Design Decisions

- **Isolation over convenience**: running the password manager on its own minimal instance, rather than alongside other self-hosted services, trades a bit of operational overhead (a separate server to maintain) for meaningfully reduced blast radius if anything else misbehaves.
- **Caddy over nginx**: chosen specifically for its zero-config automatic HTTPS via Let's Encrypt — no manual certbot setup or renewal cron needed.
- **Backing up to a separate physical location** (not just a separate instance) protects against total loss of this Oracle account/region, not just a single-service failure.

## 8. Known Limitation — Memory Pressure

Running four services (Vaultwarden, Caddy, Uptime Kuma, Glances) on a 1GB RAM instance leaves limited headroom — `free -h` showed only ~227MB genuinely available under normal load, with no swap configured. This occasionally caused Vaultwarden's web vault to load slowly or appear to hang, since WebAssembly-based crypto initialization and vault fetch both need a memory burst that the instance struggled to serve. Fixed by adding a 2GB swap file, giving the kernel headroom during those spikes rather than aggressively reclaiming cache. A real, honest tradeoff of the free-tier micro instance size — documented here rather than glossed over.

See the [Jarvis](./jarvis-reference.md) and [oracle-1](./oracle-1-reference.md) references for how this connects to the rest of the setup.
