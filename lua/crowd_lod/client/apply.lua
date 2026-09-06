CrowdLod = CrowdLod or {}

CreateClientConVar("crowdlod_enabled", "1", true, false, "Apply SetLOD to other players")
CreateClientConVar("crowdlod_near", "512", true, false, "Restore engine LOD below this distance")
CreateClientConVar("crowdlod_far", "2048", true, false, "Force max LOD at or beyond this distance")
CreateClientConVar("crowdlod_max", "3", true, false, "Forced LOD index 1..8")
CreateClientConVar("crowdlod_shadow_far", "1024", true, false, "DrawShadow(false) at or beyond this distance")
CreateClientConVar("crowdlod_min_others", "1", true, false, "Cheap LOD only when this many other players exist")
CreateClientConVar("crowdlod_think", "0.15", true, false, "Seconds between full pulses while you stand still")

hook.Add("PrePlayerDraw", "CrowdLod", function(ply, flags)
	CrowdLod.OnPrePlayerDraw(ply, flags)
end)

local nextPulse = 0
hook.Add("Think", "CrowdLod", function()
	local now = CurTime()
	if now < nextPulse then
		return
	end
	local gap = GetConVar("crowdlod_think"):GetFloat()
	if gap < 0.05 then
		gap = 0.05
	end
	nextPulse = now + gap
	CrowdLod.Pulse()
end)

concommand.Add("crowdlod_sweep", function()
	print(CrowdLod.Ticket(CrowdLod.Sweep()))
end)

concommand.Add("crowdlod_last", function()
	print(CrowdLod.Ticket(CrowdLod.Last()))
end)
