# Crowd LOD

A **client addon** for Garry's Mod dedicated-server owners. Looking at a packed hangar is slow because Source walks every bone. This forces engine LOD on **other** players and writes one last look staff can copy.

It does not paint people grey. It does not replace materials. It does not raise the 128-player cap.

Players keep their skins. Distant clones just use cheaper studio LODs when the `.mdl` actually has `$lod`.

## Who it is for

Owners whose FPS dies when they look at a crowd of custom playermodels.

Staff who need to know the model has no `$lod` instead of guessing the addon is broken.

## Install

Put this folder in `garrysmod/addons/gmod-crowd-lod` on the dedicated box so clients receive it. Restart the map.

```
crowdlod_enabled 1
crowdlod_near 512
crowdlod_far 2048
crowdlod_max 3
crowdlod_shadow_far 1024
```

Stand in a crowd, then:

```
crowdlod_sweep
```

See [docs/OPS.md](docs/OPS.md).

## What you get

| Status | Meaning |
|---|---|
| `ok` | Forced a cheaper LOD this look |
| `already` | Same LOD already applied this session |
| `no_lod` | Model has no LOD submodels. `SetLOD` cannot help |
| `skipped` | Local player, too near, disabled, or invalid |
| `missing` | No model or mesh probe returned nothing |

One ticket line:

```
crowd-lod: forced 41 to lod 3; already 6; skipped 80; missing 0; 12 models have no lod
```

## Limits

- `Entity:SetLOD` is a no-op when the QC has no `$lod`. The ticket says `no_lod`. Crowbar is the real fix.
- We never `return true` from `PrePlayerDraw`. wOS, bodygroups, and world weapons keep the engine path.
- This is not Box Clinic. Edicts stay in that sibling.
- Join Clinic is the connect ticket. This is the hangar look.

## Repo

Public tip is `lua/`, `addon.json`, docs, LICENSE. Factory eyes stay on the author machine.
