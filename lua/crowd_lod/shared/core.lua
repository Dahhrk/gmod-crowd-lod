CrowdLod = CrowdLod or {}

local SKIP_REASONS = {
	local_player = true,
	invalid = true,
	disabled = true,
	near = true,
	quiet = true,
}

function CrowdLod.ParseDistance(n)
	n = tonumber(n)
	if n == nil or n ~= n or n == math.huge or n == -math.huge or n < 0 then
		error("crowd-lod: bad distance")
	end
	return n
end

function CrowdLod.ParseLodIndex(n)
	n = tonumber(n)
	if n == nil or n ~= n or n ~= math.floor(n) then
		error("crowd-lod: bad lod")
	end
	if n ~= -1 and (n < 0 or n > 8) then
		error("crowd-lod: lod out of range")
	end
	return n
end

function CrowdLod.ParseSkipReason(reason)
	if not SKIP_REASONS[reason] then
		error("crowd-lod: unknown skip reason: " .. tostring(reason))
	end
	return reason
end

function CrowdLod.ParsePolicy(raw)
	if type(raw) ~= "table" then
		error("crowd-lod: bad policy")
	end
	local enabled = raw.enabled
	if enabled == 1 or enabled == "1" or enabled == true then
		enabled = true
	else
		enabled = false
	end
	local near = CrowdLod.ParseDistance(raw.near)
	local far = CrowdLod.ParseDistance(raw.far)
	if not (near < far) then
		error("crowd-lod: near must be < far")
	end
	local maxLod = CrowdLod.ParseLodIndex(raw.maxLod)
	if maxLod < 1 or maxLod > 8 then
		error("crowd-lod: maxLod must be 1..8")
	end
	local shadowFar = CrowdLod.ParseDistance(raw.shadowFar)
	local minOthers = tonumber(raw.minOthers)
	if minOthers == nil then
		minOthers = 1
	end
	if minOthers ~= math.floor(minOthers) or minOthers < 0 then
		error("crowd-lod: bad minOthers")
	end
	return {
		enabled = enabled,
		near = near,
		far = far,
		maxLod = maxLod,
		shadowFar = shadowFar,
		minOthers = minOthers,
	}
end

function CrowdLod.Decide(input)
	if type(input) ~= "table" or type(input.policy) ~= "table" then
		error("crowd-lod: bad decide input")
	end
	if not input.policy.enabled then
		return { kind = "skip", reason = "disabled" }
	end
	if not input.valid then
		return { kind = "skip", reason = "invalid" }
	end
	if input.isLocal then
		return { kind = "skip", reason = "local_player" }
	end
	local others = input.others
	if others == nil then
		others = 0
	end
	if others < input.policy.minOthers then
		return { kind = "skip", reason = "quiet" }
	end
	if input.dist < input.policy.near then
		return { kind = "skip", reason = "near" }
	end
	local lod
	if input.dist >= input.policy.far then
		lod = input.policy.maxLod
	else
		local span = input.policy.far - input.policy.near
		local t = (input.dist - input.policy.near) / span
		lod = math.floor(1 + t * (input.policy.maxLod - 1) + 0.0001)
		if lod < 1 then
			lod = 1
		end
		if lod > input.policy.maxLod then
			lod = input.policy.maxLod
		end
	end
	return {
		kind = "cheap",
		lod = lod,
		shadow = input.dist < input.policy.shadowFar,
	}
end

local capCache = {}

function CrowdLod.CapabilityFor(model)
	if type(model) ~= "string" or model == "" then
		return nil
	end
	local cached = capCache[model]
	if cached ~= nil then
		return cached
	end
	local a = util.GetModelMeshes(model, 0)
	local b = util.GetModelMeshes(model, 1)
	if a == nil and b == nil then
		return nil
	end
	local cap = "no_lod"
	if type(a) == "table" and type(b) == "table" and #a ~= #b then
		cap = "has_lod"
	end
	capCache[model] = cap
	return cap
end

local lastApplyByEnt = {}

function CrowdLod.ApplyDecision(ply, decision)
	if not IsValid(ply) then
		return
	end
	if decision.kind == "skip" then
		if decision.reason ~= "local_player" then
			ply:SetLOD(-1)
			ply:DrawShadow(true)
		end
		return
	end
	ply:SetLOD(decision.lod)
	ply:DrawShadow(decision.shadow)
end

function CrowdLod.Evaluate(ply, viewerEye, policy, forSweep)
	local entIndex = 0
	if IsValid(ply) then
		entIndex = ply:EntIndex()
	end
	local valid = IsValid(ply)
	local isLocal = valid and ply == LocalPlayer()
	local model = nil
	if valid then
		model = string.lower(ply:GetModel() or "")
		if model == "" then
			model = nil
		end
	end
	local dist = 0
	if valid and viewerEye then
		dist = viewerEye:Distance(ply:GetPos())
	end
	local input = {
		isLocal = isLocal,
		valid = valid,
		model = model,
		dist = dist,
		others = CrowdLod.OtherCount(),
		policy = policy,
		capability = nil,
	}
	local decision = CrowdLod.Decide(input)
	CrowdLod.ApplyDecision(ply, decision)
	if not forSweep then
		return nil
	end
	if decision.kind == "skip" then
		return {
			status = "skipped",
			entIndex = entIndex,
			model = model,
			dist = dist,
			reason = decision.reason,
		}
	end
	if model == nil then
		return {
			status = "missing",
			entIndex = entIndex,
			model = nil,
			dist = dist,
		}
	end
	local cap = CrowdLod.CapabilityFor(model)
	if cap == nil then
		return {
			status = "missing",
			entIndex = entIndex,
			model = model,
			dist = dist,
		}
	end
	if cap == "no_lod" then
		return {
			status = "no_lod",
			entIndex = entIndex,
			model = model,
			dist = dist,
			wanted = decision.lod,
			shadow = decision.shadow,
		}
	end
	local prev = lastApplyByEnt[entIndex]
	local status = "ok"
	if prev and prev.model == model and prev.lod == decision.lod and prev.shadow == decision.shadow then
		status = "already"
	else
		lastApplyByEnt[entIndex] = {
			model = model,
			lod = decision.lod,
			shadow = decision.shadow,
		}
	end
	return {
		status = status,
		entIndex = entIndex,
		model = model,
		dist = dist,
		lod = decision.lod,
		shadow = decision.shadow,
	}
end

local policyFrame = -1
local policyCache = nil
local othersFrame = -1
local othersCache = 0

function CrowdLod.OtherCount()
	local fn = FrameNumber()
	if othersFrame == fn then
		return othersCache
	end
	local n = 0
	local me = LocalPlayer()
	local list = player.GetAll()
	local i = 1
	while i <= #list do
		local ply = list[i]
		if IsValid(ply) and ply ~= me then
			n = n + 1
		end
		i = i + 1
	end
	othersFrame = fn
	othersCache = n
	return n
end

function CrowdLod.Policy()
	local fn = FrameNumber()
	if policyFrame == fn and policyCache ~= nil then
		return policyCache
	end
	policyCache = CrowdLod.ParsePolicy({
		enabled = GetConVar("crowdlod_enabled"):GetBool(),
		near = GetConVar("crowdlod_near"):GetFloat(),
		far = GetConVar("crowdlod_far"):GetFloat(),
		maxLod = GetConVar("crowdlod_max"):GetInt(),
		shadowFar = GetConVar("crowdlod_shadow_far"):GetFloat(),
		minOthers = GetConVar("crowdlod_min_others"):GetInt(),
	})
	policyFrame = fn
	return policyCache
end

function CrowdLod.Pulse()
	local policy = CrowdLod.Policy()
	local eye = EyePos()
	local list = player.GetAll()
	local i = 1
	while i <= #list do
		local ply = list[i]
		if IsValid(ply) then
			if not policy.enabled then
				if ply ~= LocalPlayer() then
					ply:SetLOD(-1)
					ply:DrawShadow(true)
				end
			else
				CrowdLod.Evaluate(ply, eye, policy, false)
			end
		end
		i = i + 1
	end
end

function CrowdLod.OnPrePlayerDraw(ply, flags)
	if not IsValid(ply) then
		return
	end
	local policy = CrowdLod.Policy()
	if not policy.enabled then
		if ply ~= LocalPlayer() then
			ply:SetLOD(-1)
			ply:DrawShadow(true)
		end
		return
	end
	CrowdLod.Evaluate(ply, EyePos(), policy, false)
end
