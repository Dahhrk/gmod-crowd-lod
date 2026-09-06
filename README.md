# Crowd LOD

A Garry's Mod client addon. It cheapens **other players** as you move. Close people stay full quality. Distant people use cheaper engine LOD. Skins stay on.

You do not run a command for that. The addon does it while you walk.

## Install

1. Put this folder in `garrysmod/addons/gmod-crowd-lod` on the dedicated server so clients get it.
2. Restart the map.
3. Join and walk toward people, then away from them.

Defaults are already on (`crowdlod_enabled 1`). Tune distances in [docs/OPS.md](docs/OPS.md) if a hangar needs different ranges.

## What happens on its own

- You walk toward someone. They use normal engine LOD. They look like themselves.
- You walk away. The client asks Source for a cheaper LOD on that player.
- You walk back. Full quality comes back.
- You turn the addon off. Other players restore to engine LOD.

Your own playermodel is left alone.

## When distant people do not get cheaper

The `.mdl` must have `$lod` in its QC. Many custom playermodels skip that. The addon still runs. `SetLOD` then does nothing to that mesh.

To see which models have no LOD, stand in a crowd and run:

```
crowdlod_sweep
```

That prints one ticket. It does not start the optimizer. The optimizer is already running.

Crowbar is how you add `$lod` to a model. This addon cannot invent LOD meshes.

## What this is not

It does not strip textures or paint players grey. It does not change wOS, bodygroups, or world weapons.
