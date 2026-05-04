#!/usr/bin/env lua

package.path = os.getenv("HOME") .. "/.local/lib/?.lua;" .. package.path
local help = require("help")
local json = require("json")

local function run(cmd)
	local handle = io.popen(cmd)
	if not handle then
		io.stderr:write("Failed to run: " .. cmd .. "\n")
		os.exit(1)
	end
	local out = handle:read("*a")
	handle:close()
	return out
end

local function hyprctl_json(args)
	return json.decode(run("hyprctl -j " .. args))
end

local function hyprctl_dispatch(...)
	local parts = { "hyprctl dispatch" }
	for _, v in ipairs({ ... }) do
		parts[#parts + 1] = tostring(v)
	end
	run(table.concat(parts, " "))
end

local function has_zero_monitor(monitor_ids)
	for _, id in ipairs(monitor_ids) do
		if id == 0 then
			return true
		end
	end
	return false
end

local function find_first_available_id(workspaces)
	local ids = {}
	for _, ws in ipairs(workspaces) do
		if ws.id >= 1 then
			ids[#ids + 1] = ws.id
		end
	end
	table.sort(ids)
	for i, id in ipairs(ids) do
		if i ~= id then
			return i
		end
	end
	return #ids + 1
end

-- Refresh: rename all workspaces to match monitor:position scheme
local function refresh()
	local workspaces = hyprctl_json("workspaces")
	local monitors = hyprctl_json("monitors")

	local monitor_ids = {}
	for _, m in ipairs(monitors) do
		monitor_ids[#monitor_ids + 1] = m.id
	end
	local zero_based = has_zero_monitor(monitor_ids)

	for _, mid in ipairs(monitor_ids) do
		local ws_ids = {}
		for _, ws in ipairs(workspaces) do
			if ws.monitorID == mid and not ws.name:find("^special:") then
				ws_ids[#ws_ids + 1] = ws.id
			end
		end
		table.sort(ws_ids)

		local display_id = zero_based and mid or (mid - 1)
		for i, wid in ipairs(ws_ids) do
			hyprctl_dispatch("renameworkspace", wid, display_id .. ":" .. i)
		end
	end
end

-- Shared state for new/move operations
local function prep(workspace_number)
	local monitors = hyprctl_json("monitors")
	local active_monitor_id
	local monitor_ids = {}
	for _, m in ipairs(monitors) do
		monitor_ids[#monitor_ids + 1] = m.id
		if m.focused then
			active_monitor_id = m.id
		end
	end
	local zero_based = has_zero_monitor(monitor_ids)
	local display_id = zero_based and active_monitor_id or (active_monitor_id - 1)

	local ws_name = display_id .. ":" .. workspace_number
	local workspaces = hyprctl_json("workspaces")
	local ws_id = nil
	for _, ws in ipairs(workspaces) do
		if ws.name == ws_name and ws.monitorID == active_monitor_id then
			ws_id = ws.id
			break
		end
	end

	return {
		workspace_name = ws_name,
		workspace_id = ws_id,
		workspaces = workspaces,
	}
end

local function rename_active_workspace(name)
	local active = hyprctl_json("activeworkspace")
	hyprctl_dispatch("renameworkspace", active.id, name)
end

local function new_workspace(number)
	local ctx = prep(number)
	if ctx.workspace_id then
		hyprctl_dispatch("workspace", ctx.workspace_id)
		return
	end
	local free_id = find_first_available_id(ctx.workspaces)
	hyprctl_dispatch("workspace", free_id)
	rename_active_workspace(ctx.workspace_name)
end

local function move_to_workspace(number)
	local ctx = prep(number)
	if ctx.workspace_id then
		hyprctl_dispatch("movetoworkspace", ctx.workspace_id)
	else
		local free_id = find_first_available_id(ctx.workspaces)
		hyprctl_dispatch("movetoworkspace", free_id)
		rename_active_workspace(ctx.workspace_name)
	end
end

local function pause_ags(fn)
	local handle = io.popen("pgrep ags 2>/dev/null")
	local pid = handle and handle:read("*l") or nil
	if handle then
		handle:close()
	end

	if pid and pid ~= "" then
		os.execute("kill -STOP " .. pid)
		local ok, err = pcall(fn)
		os.execute("kill -CONT " .. pid)
		if not ok then
			error(err)
		end
	else
		fn()
	end
end

local HELP_DETAILS = "Commands:\n"
	.. "  -n, --new NUMBER    Switch to or create workspace\n"
	.. "  -m, --move NUMBER   Move active window to workspace\n"
	.. "  -r, --refresh       Rename workspaces to match monitors\n"
	.. "\nOptions:\n"
	.. "  -h, --help          Show this message"

local function usage()
	return help.format(arg, "manage named workspaces across monitors", HELP_DETAILS)
end

local function main(args)
	if #args < 1 then
		io.stderr:write(usage())
		os.exit(1)
	end

	local cmd = args[1]
	if cmd == "--help" or cmd == "-h" then
		print(usage())
	elseif cmd == "--new" or cmd == "-n" then
		local num = args[2] and tonumber(args[2])
		if not num then
			io.stderr:write("Error: Missing or invalid workspace number.\n")
			os.exit(1)
		end
		pause_ags(function()
			new_workspace(num)
		end)
	elseif cmd == "--move" or cmd == "-m" then
		local num = args[2] and tonumber(args[2])
		if not num then
			io.stderr:write("Error: Missing or invalid workspace number.\n")
			os.exit(1)
		end
		pause_ags(function()
			move_to_workspace(num)
		end)
	elseif cmd == "--refresh" or cmd == "-r" then
		refresh()
	else
		io.stderr:write("Unknown command: " .. cmd .. "\n")
		io.stderr:write(usage())
		os.exit(1)
	end
end

main({ ... })
