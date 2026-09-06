# Crowd LOD design

## Caller

Staff look at a 128-player hangar. FPS drops. They need one sentence. How many other players we forced cheap, and how many models cannot cheapen. Players keep textures.

## Domain

One last look. Not a live stream. Not a renderer.

```
LodStatus = "ok" | "already" | "no_lod" | "skipped" | "missing"

LodPolicy
  enabled, near, far, maxLod, shadowFar

LodSweep
  map, lookedAt, policy, rows
```

`LodSweep` is the only persisted shape. Client `data/crowdlod/last-sweep.json`. Older looks are discarded.

`LodPolicy` is derived from convars each frame. Not a second store.

Unknown `status` strings error.

Counts come from rows at ticket time. JSON does not store a parallel count object.

## Shapes compared

**Sweep report (chosen).** `PrePlayerDraw` applies `SetLOD` and `DrawShadow` on other players. `crowdlod_sweep` writes one `LodSweep` and prints a ticket. Icefuse PMs often have no `$lod`. A silent policy would look dead.

**Live policy (rejected).** Same apply path, no file, no ticket. Staff cannot copy `no_lod`.

**Clay materials (rejected).** The grey screenshot. Clone Wars sells skins.

**Box Clinic tab (rejected).** `BoxReport` is edicts. Different object.

## Apply

- Other players only. Local player is `skipped`.
- Below `near`, restore `SetLOD(-1)` and leave shadows on.
- At or beyond `far`, force `maxLod` (1..8).
- Between the two, snap an integer lod in `1..maxLod`.
- At or beyond `shadowFar`, `DrawShadow(false)`.
- Never set a material. Never `DrawModel` from the hook. Never `return true` from `PrePlayerDraw`.
- Walking toward someone (`dist < near`) restores engine LOD automatically. Walking away forces `maxLod`. No command required.
- `PrePlayerDraw` calls `Evaluate(..., false)`. It applies and never probes meshes. `crowdlod_sweep` calls `Evaluate(..., true)` for the ticket.
- `crowdlod_enabled 0` restores `SetLOD(-1)` on other players.

Capability is `util.GetModelMeshes(path, 0)` vs `util.GetModelMeshes(path, 1)`. Different mesh counts means `has_lod`. Same or missing lod-1 means `no_lod`. Both nil is `missing` and is not cached as `has_lod`. The probe runs on sweep only. Look-proof can replace that body.

There is no `Entity:GetLOD`. `already` is session memory of the last apply per entity.

`PrePlayerDraw` never writes the JSON file.

## Surfaces

- Client convars `crowdlod_*`
- `crowdlod_sweep` write + print
- `crowdlod_last` reprint

No panel. No server Think. No net.

Owner ops: [OPS.md](OPS.md).

## Layout

```
lua/autorun/aaa_crowd_lod.lua   -- AddCSLuaFile + includes
lua/crowdlod/core.lua           -- Policy, Decide, apply
lua/crowdlod/sweep.lua          -- LodSweep, ParseSweep, Ticket
lua/crowdlod/client.lua         -- convars, hook, commands
```

Commands stay `crowdlod_*`. Global table stays `CrowdLod`.

## Out of scope

Box Clinic, Join Clinic, Workshop Puller, HolyLib, RenderOverride, clay materials, a second persist, LOD on `LocalPlayer`.
