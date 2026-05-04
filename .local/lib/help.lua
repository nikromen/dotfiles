-- Shared help interface for all Lua scripts.
-- Usage: package.path = os.getenv("HOME") .. "/.local/lib/?.lua;" .. package.path
--        local help = require("help")
--        help.check(arg, "description", "details")    -- auto-exits on -h/--help
--        help.format(arg, "description", "details")   -- returns formatted string

local M = {}

function M.format(args, description, details)
	local script = (args and args[0]) or "script"
	script = script:match("[^/]+$") or script
	local out = string.format("%s - %s\n\nUsage: %s [-h|--help]", script, description, script)
	if details then
		out = out .. "\n\n" .. details
	end
	return out .. "\n"
end

function M.check(args, description, details)
	if args[1] == "-h" or args[1] == "--help" then
		io.write(M.format(args, description, details))
		os.exit(0)
	end
end

return M
