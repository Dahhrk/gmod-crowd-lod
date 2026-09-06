CrowdLod = CrowdLod or {}

if SERVER then
	AddCSLuaFile("crowdlod/core.lua")
	AddCSLuaFile("crowdlod/sweep.lua")
	AddCSLuaFile("crowdlod/client.lua")
end

if CLIENT then
	include("crowdlod/core.lua")
	include("crowdlod/sweep.lua")
	include("crowdlod/client.lua")
end
