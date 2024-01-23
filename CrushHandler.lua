local projectName = "buckshot"
local path = string.gsub(require('shell').resolve(require('process').info().path),'CrushHandler', projectName..".lua")
local programmHandle, why = loadfile(path)
local function call(method, ...)
	local args = {...}

	local function launchMethod()
		method(table.unpack(args))
	end

	local function tracebackMethod(xpcallTraceback)
		local debugTraceback = debug.traceback()
		local path, line, tailCallsStart = debugTraceback
		
		while true do
			tailCallsStart = path:find("%.%.%.tail calls%.%.%.%)")

			if tailCallsStart then
				path = path:sub(tailCallsStart + 17)
			else
				break
			end
		end

		path, line = path:match("\t+([^:]+%.lua):(%d+):")

		-- Weird case on some server machines, unable to reproduce,
		-- seems like traceback parsing error
		-- TODO: replace this when appropriate error reason will be found
		if not path then
			return nil
		end

		return {
			path = path,
			line = tonumber(line),
			traceback = tostring(xpcallTraceback) .. "\n" .. debugTraceback
		}
	end
	
	local xpcallSuccess, xpcallReason = xpcall(launchMethod, tracebackMethod)
	-- This shouldn't happen normally, but if so - placeholder error message will be returned
	if type(xpcallReason) == "string" or xpcallReason == nil then
		xpcallReason = {
			path = "UNKNOWN",
			line = 1,
			traceback = "system fatal error: " .. tostring(xpcallReason)
		}
	end

	if not xpcallSuccess and not xpcallReason.traceback:match("^table") and not xpcallReason.traceback:match("interrupted") then
		return false, xpcallReason.path, xpcallReason.line, xpcallReason.traceback
	end

	return true
end
if type(programmHandle) ~= 'function' and why then
	require('term').clear()
	require('component').gpu.setActiveBuffer(0)
	io.stderr:write(why..'\n')
end
local suc, path, line, traceback = call(programmHandle)
if suc == false then
	require('term').clear()
	require('component').gpu.setActiveBuffer(0)
	require('component').gpu.freeBuffer(allocatedBuffer)
	allocatedBuffer = nil
	io.stderr:write(traceback..'\n')
end