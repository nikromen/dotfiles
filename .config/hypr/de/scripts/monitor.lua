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

local HELP_DETAILS = "Commands:\n"
	.. "  -r, --right   Move current workspace to the monitor on the right\n"
	.. "  -l, --left    Move current workspace to the monitor on the left\n"
	.. "\nOptions:\n"
	.. "  -h, --help    Show this message"

local function usage()
	return help.format(arg, "swap workspaces between monitors", HELP_DETAILS)
end

local function move(direction)
	local monitors = json.decode(run("hyprctl -j monitors"))

	table.sort(monitors, function(a, b)
		return a.x < b.x
	end)

	local current_idx
	for i, m in ipairs(monitors) do
		if m.focused then
			current_idx = i
			break
		end
	end

	if not current_idx then
		run('notify-send -a "Hyprland" -i "error" -c "error" "No focused monitor found."')
		os.exit(1)
	end

	local next_idx
	if direction == "right" then
		next_idx = current_idx + 1
	else
		next_idx = current_idx - 1
	end

	if next_idx < 1 or next_idx > #monitors then
		run('notify-send -a "Hyprland" -i "error" -c "error" "No monitor to move to."')
		os.exit(1)
	end

	local cur = monitors[current_idx]
	local nxt = monitors[next_idx]

	local cur_ws = cur.activeWorkspace
	local nxt_ws = nxt.activeWorkspace

	local cur_pos = cur_ws.name:match(":(%d+)$") or "1"
	local nxt_pos = nxt_ws.name:match(":(%d+)$") or "1"

	local batch = string.format(
		"dispatch renameworkspace %d %d:%s; dispatch renameworkspace %d %d:%s; dispatch focusworkspaceoncurrentmonitor %d",
		cur_ws.id,
		nxt.id,
		nxt_pos,
		nxt_ws.id,
		cur.id,
		cur_pos,
		nxt_ws.id
	)
	run("hyprctl --batch '" .. batch .. "'")
end

local function main(args)
	if #args < 1 then
		io.stderr:write(usage())
		os.exit(1)
	end

	local cmd = args[1]
	if cmd == "-r" or cmd == "--right" then
		move("right")
	elseif cmd == "-l" or cmd == "--left" then
		move("left")
	elseif cmd == "-h" or cmd == "--help" then
		print(usage())
	else
		io.stderr:write("Unknown option: " .. cmd .. "\n")
		io.stderr:write(usage())
		os.exit(1)
	end
end

main({ ... })
