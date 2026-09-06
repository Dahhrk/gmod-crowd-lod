CrowdLod = CrowdLod or {}

local DATA_PATH = "crowdlod/last-sweep.json"

local STATUSES = {
	ok = true,
	already = true,
	no_lod = true,
	skipped = true,
	missing = true,
}

function CrowdLod.ParseStatus(status)
	if not STATUSES[status] then
		error("unknown lod status: " .. tostring(status))
	end
	return status
end

function CrowdLod.CountsFromRows(rows, policy)
	local counts = {
		ok = 0,
		already = 0,
		no_lod = 0,
		skipped = 0,
		missing = 0,
		forced = 0,
		noLodModels = 0,
	}
	local seen = {}
	local i = 1
	while i <= #rows do
		local row = rows[i]
		local status = CrowdLod.ParseStatus(row.status)
		counts[status] = counts[status] + 1
		if (status == "ok" or status == "already") and row.lod == policy.maxLod then
			counts.forced = counts.forced + 1
		end
		if status == "no_lod" and type(row.model) == "string" and not seen[row.model] then
			seen[row.model] = true
			counts.noLodModels = counts.noLodModels + 1
		end
		i = i + 1
	end
	return counts
end

function CrowdLod.Ticket(sweep)
	local counts = CrowdLod.CountsFromRows(sweep.rows, sweep.policy)
	return string.format(
		"crowd-lod: forced %d to lod %d; already %d; skipped %d; missing %d; %d models have no lod",
		counts.forced,
		sweep.policy.maxLod,
		counts.already,
		counts.skipped,
		counts.missing,
		counts.noLodModels
	)
end

local function parseRow(raw)
	if type(raw) ~= "table" then
		error("crowd-lod: bad row")
	end
	local status = CrowdLod.ParseStatus(raw.status)
	local entIndex = tonumber(raw.entIndex) or 0
	local dist = CrowdLod.ParseDistance(raw.dist)
	local model = raw.model
	if model == "" then
		model = nil
	end
	if status == "ok" or status == "already" then
		if type(model) ~= "string" then
			error("crowd-lod: ok/already needs a model")
		end
		return {
			status = status,
			entIndex = entIndex,
			model = string.lower(model),
			dist = dist,
			lod = CrowdLod.ParseLodIndex(raw.lod),
			shadow = raw.shadow and true or false,
		}
	end
	if status == "no_lod" then
		if type(model) ~= "string" then
			error("crowd-lod: no_lod needs a model")
		end
		return {
			status = "no_lod",
			entIndex = entIndex,
			model = string.lower(model),
			dist = dist,
			wanted = CrowdLod.ParseLodIndex(raw.wanted),
			shadow = raw.shadow and true or false,
		}
	end
	if status == "skipped" then
		return {
			status = "skipped",
			entIndex = entIndex,
			model = type(model) == "string" and string.lower(model) or nil,
			dist = dist,
			reason = CrowdLod.ParseSkipReason(raw.reason),
		}
	end
	if status == "missing" then
		return {
			status = "missing",
			entIndex = entIndex,
			model = type(model) == "string" and string.lower(model) or nil,
			dist = dist,
		}
	end
	error("unknown lod status: " .. tostring(status))
end

function CrowdLod.ParseSweep(raw)
	if type(raw) ~= "table" then
		error("crowd-lod: bad sweep")
	end
	local policy = CrowdLod.ParsePolicy(raw.policy)
	if type(raw.rows) ~= "table" then
		error("crowd-lod: bad rows")
	end
	local rows = {}
	local i = 1
	while i <= #raw.rows do
		rows[i] = parseRow(raw.rows[i])
		i = i + 1
	end
	if type(raw.map) ~= "string" or raw.map == "" then
		error("crowd-lod: bad map")
	end
	if type(raw.lookedAt) ~= "string" or raw.lookedAt == "" then
		error("crowd-lod: bad lookedAt")
	end
	return {
		map = raw.map,
		lookedAt = raw.lookedAt,
		policy = policy,
		rows = rows,
	}
end

function CrowdLod.Sweep()
	local policy = CrowdLod.Policy()
	local eye = EyePos()
	local rows = {}
	local list = player.GetAll()
	local i = 1
	while i <= #list do
		rows[i] = CrowdLod.Evaluate(list[i], eye, policy)
		i = i + 1
	end
	local sweep = {
		map = game.GetMap(),
		lookedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		policy = policy,
		rows = rows,
	}
	file.CreateDir("crowdlod")
	file.Write(DATA_PATH, util.TableToJSON(sweep, true))
	return sweep
end

function CrowdLod.Last()
	local blob = file.Read(DATA_PATH, "DATA")
	if not blob then
		error("crowd-lod: no last sweep")
	end
	local raw = util.JSONToTable(blob)
	if not raw then
		error("crowd-lod: corrupt last sweep")
	end
	return CrowdLod.ParseSweep(raw)
end
