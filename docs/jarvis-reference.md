# Jarvis Server — Architecture Reference

Ubuntu 24.04 · Docker · Tailscale · Cosmos OS

> This is a sanitized reference for the public repo. All IPs, domains, tokens, and API keys have been replaced with placeholders — see the personal (private) copy for real values.

## 1. Network Identity

| | |
|---|---|
| Hostname | jarvis |
| OS | Ubuntu 24.04 LTS Server |
| LAN IP (static) | `<JARVIS_LAN_IP>` |
| Tailscale IP | `<JARVIS_TAILSCALE_IP>` |
| Domain | `<JARVIS_DUCKDNS_DOMAIN>` |

Static IP is configured via `/etc/netplan/01-netcfg.yaml` so the LAN IP survives router changes.

## 2. Hardware

Repurposed laptop, running headless: Intel Core i3-6006U (2 cores), 8GB DDR4, 490GB SSD, Intel HD Graphics 520 (VAAPI hardware transcoding enabled).

## 3. Services Overview

| Service | Purpose |
|---|---|
| Cosmos OS | Reverse proxy, SSL termination via Let's Encrypt |
| Pi-hole + Unbound | DNS filtering + recursive resolver (no upstream Google/Cloudflare dependency) |
| Jellyfin + arr stack (Radarr, Sonarr ×2, Prowlarr, qBittorrent, Jellyseerr) | Media automation pipeline |
| Nextcloud | File sync |
| Immich | Self-hosted photo backup |
| Homepage | Central dashboard, 4×3 grid layout across all three servers |
| Uptime Kuma | Service monitoring (part of a cross-server monitoring triangle — see below) |
| Glances | Live system metrics, pulled into Homepage |
| n8n | Workflow automation (e.g. auto-sync new media to a Windows laptop) |
| Code-Server | Browser-based VS Code |
| iSponsorBlockTV | Auto-skip YouTube ads/sponsors on a paired smart TV |

Container configs for each service live in [`jarvis/containers/`](../jarvis/containers/).

## 4. Networking Architecture

**DNS chain:** Device → Pi-hole → Unbound → Root DNS servers (no third-party resolver in the path).

**Reverse proxy:** Cosmos OS handles all traffic on ports 80/443, terminating TLS via Let's Encrypt for domain-based access. Services accessed by direct IP:port bypass Cosmos.

**Remote access:** Tailscale mesh VPN connects Jarvis to both Oracle Cloud instances and a personal laptop, with MagicDNS for name-based access. Jarvis also runs as a Tailscale exit node.

## 5. Homepage Dashboard

4-column-wide, 4-row dashboard aggregating all three servers (Jarvis, oracle-1, vault-server) into one view — live CPU/memory/disk metrics via Glances, service status via Uptime Kuma, and quick-launch links for every hosted app. See [`jarvis/services.yaml`](../jarvis/services.yaml), [`settings.yaml`](../jarvis/settings.yaml), and [`custom.css`](../jarvis/custom.css) (custom CSS overrides Homepage's default 4-column grid to a 3-column layout).

## 6. Cross-Server Monitoring

Rather than a single monitoring point (which can't alert if it goes down itself), monitoring is split across a triangle:

| Uptime Kuma instance | Watches |
|---|---|
| Jarvis's | oracle-1, vault-server |
| vault-server's | Jarvis, oracle-1 |

oracle-1 doesn't run its own Uptime Kuma — it's covered externally by the other two, closing the single-point-of-failure gap.

## 7. Media Automation Pipeline

```
Jellyseerr → Radarr/Sonarr → Prowlarr → qBittorrent → media storage → Jellyfin auto-detects
```

Sonarr runs as two separate instances (TV vs. Anime) with different root folders and series-type settings, both pointed at the same Prowlarr indexer set. FlareSolverr proxies Cloudflare-protected indexers.

## 8. Notable Design Decisions

- **VAAPI hardware transcoding** on Jellyfin reduced per-stream CPU load from ~90% to ~15%, critical given the modest CPU.
- **Recursive DNS (Unbound) instead of upstream resolvers** — queries root DNS servers directly for privacy, with Pi-hole handling ad-blocking on top.
- **Vaultwarden was migrated off Jarvis entirely** to a dedicated, isolated Oracle instance (see the vault-server reference) — so a password manager doesn't share fate with a media server that gets restarted/modified often.

See the [oracle-1](./oracle-1-reference.md) and [vault-server](./vault-server-reference.md) references for how those pieces connect.
