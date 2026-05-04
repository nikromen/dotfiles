#!/usr/bin/env lua

package.path = os.getenv("HOME") .. "/.local/lib/?.lua;" .. package.path
local help = require("help")
local json = require("json")

help.check(arg, "switch keyboard layout and show notification")

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

local instance = os.getenv("HYPRLAND_INSTANCE")
local hyprctl = instance and ("hyprctl --instance " .. instance) or "hyprctl"
local devices = json.decode(run(hyprctl .. " devices -j"))

local active_kb
for _, kb in ipairs(devices.keyboards) do
	if kb.main then
		active_kb = kb.name
		break
	end
end

if not active_kb then
	io.stderr:write("No main keyboard found.\n")
	os.exit(1)
end

-- TODO: won't switch for every keyboard
run(hyprctl .. " switchxkblayout " .. active_kb .. " next")

local updated = json.decode(run(hyprctl .. " devices -j"))
for _, kb in ipairs(updated.keyboards) do
	if kb.main then
		local icons_dir = os.getenv("WM_ICONS") or ""
		run(
			string.format(
				'notify-send -e -u low -t 1500 -h string:x-canonical-private-synchronous:keyboard_notify -i "%s/keyboard.png" "%s"',
				icons_dir,
				kb.active_keymap
			)
		)
		break
	end
end
