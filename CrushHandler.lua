local projectName = "buckshot"
local beep = require('computer').beep
local path = string.gsub(require('shell').resolve(require('process').info().path),'CrushHandler', projectName..".lua")
beep(50,0.05)
local programmHandle, why = loadfile(path)
if type(programmHandle) ~= 'function' and why then
	require('term').clear()
	require('component').gpu.setActiveBuffer(0)
	io.stderr:write(why..'\n')
	beep(450,0.1)
	return
end
--MineOS System.call function
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
local suc, _, _, traceback = call(programmHandle)
if suc == false then
	require('component').gpu.setActiveBuffer(0)
	require('component').gpu.freeBuffer(allocatedBuffer)
	allocatedBuffer = nil
	io.stderr:write(traceback..'\n')
	beep(450,0.1)
	beep(450,0.1)
	return
end
beep(20,0.05)