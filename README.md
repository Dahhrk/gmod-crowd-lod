# Crowd LOD

A Garry's Mod client addon. It cheapens **other players** by distance. Close people stay full quality. Distant people use cheaper engine LOD. Skins stay on.

It runs by itself. Walking and standing still both keep it current. It only cheapens when at least one other player is on the box and they are far enough.

## Install

1. Put this folder in `garrysmod/addons/gmod-crowd-lod` on the dedicated server so clients get it.
2. Restart the map.
3. Join. Walk or stand still. Look toward people and away from them.

Defaults are already on (`crowdlod_enabled 1`). Tune distances in [docs/OPS.md](docs/OPS.md) if a hangar needs different ranges.

## What happens on its own

- Someone is close (inside `crowdlod_near`, default 512). They stay full quality.
- Someone is farther. The client asks Source for a cheaper LOD.
- You stand still. A short Think pulse keeps those distances up to date.
- You are alone. Nothing is cheapened. The addon waits until someone else is there.
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
