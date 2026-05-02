# Oracle-1 Server — Architecture Reference

Minecraft Server + Crafty Controller · Oracle Cloud (Always Free)

> Sanitized reference — see private copy for real IPs/credentials.

## 1. Network Identity

| | |
|---|---|
| Instance shape | VM.Standard.A1.Flex (Ampere ARM, Always Free) — 2 OCPU, 12GB RAM |
| OS | Ubuntu 24.04.4 LTS (aarch64) |
| Public IP | `<ORACLE1_PUBLIC_IP>` |
| Tailscale IP | `<ORACLE1_TAILSCALE_IP>` |

## 2. Architecture

Minecraft (Fabric 26.2) runs under **Crafty Controller**, a Dockerized web panel that manages the server process, mods, whitelist, and console — replacing an earlier direct-systemd setup. Crafty itself is reachable only over Tailscale (never exposed publicly), since it's a full admin panel with file/console access.

```
Player → Public IP:25565 → Minecraft (Fabric, managed by Crafty)
Admin  → Tailscale IP:8443 → Crafty Controller web UI
```

## 3. Storage & Backups

A dedicated 100GB Oracle block volume is mounted at `/mnt/backups`. A daily cron job (`backup-minecraft.sh`, see [`oracle-1/scripts/`](../oracle-1/scripts/)) tars the live server folder (world, mods, configs) into this volume, keeping the last 7 backups and pruning older ones automatically.

## 4. Networking & Security

| Port | Purpose | Exposure |
|---|---|---|
| 22 | SSH | Public |
| 25565 | Minecraft | Public |
| 25575 | RCON | Restricted to a single trusted Tailscale IP |
| 61208 | Glances (metrics) | Restricted to Jarvis's Tailscale IP |
| 8443 | Crafty Controller | Tailscale-only, never opened publicly |

Two firewall layers are involved: OS-level `iptables` and Oracle Cloud's own Security List — both need matching rules for a port to actually be reachable, which was a repeated source of debugging during setup (a rule in one layer without the other silently fails).

## 5. Notable Design Decisions

- **Client compatibility drove several choices**: players connect via TLauncher (an offline/unauthenticated launcher), which required setting `online-mode=false` on the server — a deliberate tradeoff, mitigated by keeping the whitelist enabled so only approved usernames can join.
- **Migrating from a bare systemd service to Crafty Controller** made mod management, whitelist edits, and console access possible without SSH for every routine change — meaningfully lowering the friction of day-to-day server administration.
- **Version-mismatch mod debugging**: a modpack initially built for an older Minecraft version failed to load under the newer one; Fabric's crash reports pinpointed the exact incompatible mod by name, which made triage fast once the right log was checked.
- **No local monitoring instance** — oracle-1 is deliberately watched externally by both Jarvis and vault-server's Uptime Kuma instances, avoiding a server needing to self-report its own downtime.

See the [Jarvis](./jarvis-reference.md) reference for the cross-server monitoring setup this participates in.
