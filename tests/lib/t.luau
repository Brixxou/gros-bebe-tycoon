-- Mini framework de test pour Lune : describe / it / assertions.
local T = {}

type Results = { passed: number, failed: number, failures: { string } }

local results: Results = { passed = 0, failed = 0, failures = {} }
local suite = ""

local function show(value: any): string
	if type(value) == "string" then
		return string.format("%q", value)
	end
	return tostring(value)
end

function T.describe(name: string, body: () -> ())
	local previous = suite
	suite = if previous == "" then name else previous .. " > " .. name
	body()
	suite = previous
end

function T.it(name: string, body: () -> ())
	local ok, err = pcall(body)
	if ok then
		results.passed += 1
	else
		results.failed += 1
		table.insert(results.failures, suite .. " > " .. name .. "\n    " .. tostring(err))
	end
end

function T.eq(actual: any, expected: any, label: string?)
	if actual ~= expected then
		local prefix = if label then label .. " : " else ""
		error(prefix .. "attendu " .. show(expected) .. ", obtenu " .. show(actual), 2)
	end
end

function T.near(actual: number, expected: number, tolerance: number?)
	local margin = tolerance or 1e-9
	if math.abs(actual - expected) > margin then
		error("attendu ~" .. tostring(expected) .. ", obtenu " .. tostring(actual), 2)
	end
end

function T.truthy(value: any, label: string?)
	if not value then
		error((label or "valeur") .. " devrait être vraie", 2)
	end
end

function T.results(): Results
	return results
end

return T
