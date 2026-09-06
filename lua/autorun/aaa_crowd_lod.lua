CrowdLod = CrowdLod or {}

if SERVER then
	AddCSLuaFile("crowd_lod/shared/core.lua")
	AddCSLuaFile("crowd_lod/shared/sweep.lua")
	AddCSLuaFile("crowd_lod/client/apply.lua")
end

if CLIENT then
	include("crowd_lod/shared/core.lua")
	include("crowd_lod/shared/sweep.lua")
	include("crowd_lod/client/apply.lua")
end
