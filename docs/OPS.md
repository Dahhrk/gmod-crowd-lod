# Ops — Crowd LOD for server owners

This addon cheapens **other players** on the client. It does not fix edicts. It does not download Workshop. It does not paint models grey.

## Install (dedicated)

1. Put the addon folder in `garrysmod/addons/gmod-crowd-lod`.
2. Keep `lua/autorun/aaa_crowd_lod.lua` so the dedicated box sends the client files.
3. Restart the map.
4. Join. Walk toward and away from other players. LOD applies on its own. `crowdlod_sweep` only prints the ticket.

Hosted panels (Icefuse, Pingperfect, etc.): upload via FTP/SFTP into `garrysmod/addons/`.

## Convars (client)

| Convar | Default | Meaning |
|---|---|---|
| `crowdlod_enabled` | 1 | Apply on every other-player draw. `0` restores engine LOD |
| `crowdlod_near` | 512 | Engine auto LOD closer than this |
| `crowdlod_far` | 2048 | Force `crowdlod_max` at or beyond this |
| `crowdlod_max` | 3 | LOD index 1..8 |
| `crowdlod_shadow_far` | 1024 | Turn player shadows off at or beyond this |

`near` must stay below `far`.

## Commands

| Command | What |
|---|---|
| `crowdlod_sweep` | Snapshot every player, overwrite `data/crowdlod/last-sweep.json`, print the ticket |
| `crowdlod_last` | Reprint the last ticket |

Ticket:

```
crowd-lod: forced 41 to lod 3; already 6; skipped 80; missing 0; 12 models have no lod
```

`no_lod` means the QC has no `$lod`. Recompile that playermodel. This addon cannot invent LOD meshes.

## What not to do

- Do not enable `mat_queue_mode 2` as a "renderer." White flickering clothes are a bug.
- Do not drop this into Box Clinic or Join Clinic.
- Do not strip materials.
