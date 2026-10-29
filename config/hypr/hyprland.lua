-- Hyprland Lua config (converted from the legacy hyprland.conf + UserConfigs/*.conf)
-- The old .conf files are kept untouched. Delete or rename this file to go back to them.
-- Check for errors with: Hyprland --verify-config -c ~/.config/hypr/hyprland.lua

local HOME = os.getenv("HOME")
local hyprDir = HOME .. "/.config/hypr"
local scriptsDir = hyprDir .. "/scripts"
local UserScripts = hyprDir .. "/UserScripts"

local mainMod = "SUPER"

-- helpers that scripts in scripts/ call via `hyprctl eval 'kool.xxx()'`
kool = kool or {}

local function bind(keys, dsp, opts)
	return hl.bind(keys, dsp, opts)
end

local function exec(cmd)
	return hl.dsp.exec_cmd(cmd)
end

------------------
---- MONITORS ----
------------------
-- (was monitors.conf)
-- HDMI-A-1 (Samsung) is capped at 340 MHz TMDS: keep it at 4K@30, 4K@60 makes the connector flap.
hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@30", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "3840x2160", position = "3840x0", scale = 1 })

-- (was workspaces.conf)
-- 1-4 on DP, 5-10 on HDMI
for i = 1, 10 do
	local ws = tostring(i)
	if i <= 4 then
		hl.workspace_rule({ workspace = ws, monitor = "DP-2", default = (i == 1) })
	else
		hl.workspace_rule({ workspace = ws, monitor = "HDMI-A-1", default = (i == 8) })
	end
end

-----------------------
---- USER DEFAULTS ----
-----------------------
-- (was UserConfigs/01-UserDefaults.conf)
hl.env("EDITOR", "nvim")

local term = "kitty"
local files = "thunar"
local ghostty = "ghostty"
local privateBrowser = "vivaldi --incognito --class=privateBrowser"
local browser = "vivaldi"

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
-- (was UserConfigs/ENVariables.conf)
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QUICK_CONTROLS_STYLE", "org.hyprland.style")
hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-------------------
---- AUTOSTART ----
-------------------
-- (was exec-once in hyprland.conf and UserConfigs/Startup_Apps.conf)
hl.on("hyprland.start", function()
	hl.exec_cmd(hyprDir .. "/initial-boot.sh")
	hl.exec_cmd("awww-daemon --format xrgb")
	hl.exec_cmd('awww img $(ls $HOME/Pictures/wallpapers | shuf -n 1 | sed "s|^|$HOME/Pictures/wallpapers/|")')
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd(scriptsDir .. "/Polkit.sh")
	hl.exec_cmd("nm-applet --indicator")
	hl.exec_cmd("swaync")
	hl.exec_cmd("waybar")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("hypridle")
	kool.rainbow_borders() -- was UserScripts/RainbowBorders.sh
end)

----------------------------
---- LOOK AND FEEL      ----
----------------------------
-- Colors come from wallust (~/.config/hypr/wallust/wallust-hyprland.conf, still written by wallust).
-- The file is re-read every 2s so wallpaper changes update the borders like the old autoreload did.
local wallustFile = hyprDir .. "/wallust/wallust-hyprland.conf"

local function readFile(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local s = f:read("a")
	f:close()
	return s
end

local function parseWallust(text)
	local c = {}
	for name, value in (text or ""):gmatch("%$([%w_]+)%s*=%s*(rgba?%b())") do
		c[name] = value
	end
	return c
end

local function applyColors(c)
	hl.config({
		general = {
			col = {
				active_border = c.color12 or "rgb(658582)",
				inactive_border = c.color10 or "rgb(5D494B)",
			},
		},
		decoration = {
			shadow = {
				color = c.color12 or "rgb(658582)",
				color_inactive = c.color10 or "rgb(5D494B)",
			},
		},
		group = {
			col = { border_active = c.color15 or "rgb(F2E4D2)" },
			groupbar = { col = { active = c.color0 or "rgb(3E4042)" } },
		},
	})
end

local wallustText = readFile(wallustFile)
applyColors(parseWallust(wallustText))

-- timers are dropped on every reload, so (re)create it from events.
-- (creating it at top level crashes `Hyprland --verify-config`, which has no event loop)
local function startWallustWatcher()
	hl.timer(function()
		local text = readFile(wallustFile)
		if text and text ~= wallustText then
			wallustText = text
			applyColors(parseWallust(text))
		end
	end, { timeout = 2000, type = "repeat" })
end

hl.on("hyprland.start", startWallustWatcher)
hl.on("config.reloaded", function()
	-- verify-config also fires this, but without any monitors
	if #hl.get_monitors() > 0 then
		startWallustWatcher()
	end
end)

function kool.rainbow_borders()
	local colors = {}
	for i = 1, 10 do
		colors[i] = string.format("rgba(%06xff)", math.random(0, 0xffffff))
	end
	hl.config({ general = { col = { active_border = { colors = colors, angle = 270 } } } })
end

-- (was UserConfigs/UserDecorations.conf)
hl.config({
	general = {
		border_size = 2,
		gaps_in = 2,
		gaps_out = 4,
	},

	decoration = {
		rounding = 10,
		active_opacity = 1.0,
		inactive_opacity = 0.9,
		fullscreen_opacity = 1.0,
		dim_inactive = true,
		dim_strength = 0.1,
		dim_special = 0.8,

		shadow = {
			enabled = true,
			range = 3,
			render_power = 1,
		},

		blur = {
			enabled = true,
			size = 6,
			passes = 2,
			ignore_opacity = true,
			new_optimizations = true,
			special = true,
			popups = true,
		},
	},
})

-- (was UserConfigs/UserAnimations.conf)
hl.config({ animations = { enabled = true } })

local function bezier(name, x1, y1, x2, y2)
	hl.curve(name, { type = "bezier", points = { { x1, y1 }, { x2, y2 } } })
end

bezier("wind", 0.05, 0.9, 0.1, 1.05)
bezier("winIn", 0.1, 1.1, 0.1, 1.1)
bezier("winOut", 0.3, -0.3, 0, 1)
bezier("liner", 1, 1, 1, 1)
bezier("overshot", 0.05, 0.9, 0.1, 1.05)
bezier("smoothOut", 0.5, 0, 0.99, 0.99)
bezier("smoothIn", 0.5, -0.5, 0.68, 1.5)

hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "wind", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
-- speed is capped at 100 now (was 180); used by rainbow borders
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "liner", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "smoothOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "overshot" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 5, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5, bezier = "winOut", style = "slide" })

------------------------
---- USER SETTINGS  ----
------------------------
-- (was UserConfigs/UserSettings.conf)
hl.config({
	dwindle = {
		preserve_split = true,
		special_scale_factor = 0.8,
	},

	master = {
		new_status = "master",
		new_on_top = true,
		mfact = 0.5,
	},

	general = {
		resize_on_border = true,
		layout = "dwindle",
	},

	input = {
		kb_layout = "us, lv",
		kb_variant = "",
		kb_model = "",
		kb_options = "caps:swapescape, grp:alt_shift_toggle",
		kb_rules = "",

		repeat_rate = 50,
		repeat_delay = 300,
		sensitivity = 0,
		numlock_by_default = true,
		left_handed = false,
		follow_mouse = true,
		float_switch_override_focus = false,

		touchpad = {
			disable_while_typing = true,
			natural_scroll = true,
			clickfinger_behavior = false,
			middle_button_emulation = true,
			tap_to_click = true,
			drag_lock = false,
		},

		touchdevice = {
			enabled = true,
		},

		tablet = {
			transform = 0,
			left_handed = false,
		},
	},

	gestures = {
		workspace_swipe_distance = 500,
		workspace_swipe_invert = true,
		workspace_swipe_min_speed_to_force = 30,
		workspace_swipe_cancel_ratio = 0.5,
		workspace_swipe_create_new = true,
		workspace_swipe_forever = true,
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		vrr = 2,
		mouse_move_enables_dpms = true,
		enable_swallow = false,
		swallow_regex = "^(kitty)$",
		focus_on_activate = false,
		initial_workspace_tracking = 0,
		middle_click_paste = false,
	},

	binds = {
		workspace_back_and_forth = true,
		allow_workspace_cycles = true,
		pass_mouse_when_bound = false,
	},

	xwayland = {
		enabled = true,
		force_zero_scaling = true,
	},

	render = {
		direct_scanout = 0,
	},

	cursor = {
		sync_gsettings_theme = true,
		no_hardware_cursors = 2,
		enable_hyprcursor = true,
		warp_on_change_workspace = 2,
		no_warps = true,
	},
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

----------------
---- LAPTOP ----
----------------
-- (was UserConfigs/Laptops.conf)
local touchpadDevice = "asue1209:00-04f3:319f-touchpad"

-- scripts/TouchPad.sh stores the on/off state here; honour it across reloads
local touchpadStatus = readFile((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/touchpad.status")

function kool.set_touchpad(enabled)
	hl.device({ name = touchpadDevice, enabled = enabled })
end

kool.set_touchpad(touchpadStatus ~= "false")

bind("XF86KbdBrightnessDown", exec(scriptsDir .. "/BrightnessKbd.sh --dec"), { repeating = true })
bind("XF86KbdBrightnessUp", exec(scriptsDir .. "/BrightnessKbd.sh --inc"), { repeating = true })
bind("XF86Launch1", exec("rog-control-center")) -- ASUS Armory crate button
bind("XF86Launch3", exec("asusctl led-mode -n")) -- FN+F4 switch keyboard RGB profile
bind("XF86Launch4", exec("asusctl profile -n")) -- FN+F5 fan profiles
bind("XF86MonBrightnessDown", exec(scriptsDir .. "/Brightness.sh --dec"), { repeating = true })
bind("XF86MonBrightnessUp", exec(scriptsDir .. "/Brightness.sh --inc"), { repeating = true })
bind("XF86TouchpadToggle", exec(scriptsDir .. "/TouchPad.sh"))

bind(mainMod .. " + F6", exec(scriptsDir .. "/ScreenShot.sh --now"))
bind(mainMod .. " + SHIFT + F6", exec(scriptsDir .. "/ScreenShot.sh --area"))
bind(mainMod .. " + CTRL + F6", exec(scriptsDir .. "/ScreenShot.sh --in5"))
bind(mainMod .. " + ALT + F6", exec(scriptsDir .. "/ScreenShot.sh --in10"))
bind("ALT + F6", exec(scriptsDir .. "/ScreenShot.sh --active"))

---------------------
---- KEYBINDINGS ----
---------------------
-- (was configs/Keybinds.conf)
bind("CTRL + ALT + Delete", hl.dsp.exit())
bind(mainMod .. " + Q", hl.dsp.window.close())
bind(mainMod .. " + SHIFT + Q", exec(scriptsDir .. "/KillActiveProcess.sh"))
bind("CTRL + ALT + L", exec(scriptsDir .. "/LockScreen.sh"))
bind("CTRL + ALT + P", exec(scriptsDir .. "/Wlogout.sh"))
bind(mainMod .. " + SHIFT + N", exec("swaync-client -t -sw"))
bind(mainMod .. " + SHIFT + E", exec(scriptsDir .. "/Kool_Quick_Settings.sh"))

-- master layout
bind(mainMod .. " + CTRL + D", hl.dsp.layout("removemaster"))
bind(mainMod .. " + I", hl.dsp.layout("addmaster"))
local bindJ = bind(mainMod .. " + J", hl.dsp.layout("cyclenext"))
local bindK = bind(mainMod .. " + K", hl.dsp.layout("cycleprev"))
bind(mainMod .. " + CTRL + Return", hl.dsp.layout("swapwithmaster"))

-- dwindle layout
bind(mainMod .. " + SHIFT + I", hl.dsp.layout("togglesplit"))
bind(mainMod .. " + P", hl.dsp.window.pseudo())
bind(mainMod .. " + M", hl.dsp.layout("splitratio 0.3"))

-- groups
bind(mainMod .. " + G", hl.dsp.group.toggle())
bind(mainMod .. " + CTRL + tab", hl.dsp.group.next())

bind("ALT + tab", function()
	hl.dispatch(hl.dsp.window.cycle_next())
	hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- special keys
bind("XF86AudioRaiseVolume", exec(scriptsDir .. "/Volume.sh --inc"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume", exec(scriptsDir .. "/Volume.sh --dec"), { locked = true, repeating = true })
bind("XF86AudioMicMute", exec(scriptsDir .. "/Volume.sh --toggle-mic"), { locked = true })
bind("XF86AudioMute", exec(scriptsDir .. "/Volume.sh --toggle"), { locked = true })
bind("XF86Sleep", exec("systemctl suspend"), { locked = true })
bind("XF86Rfkill", exec(scriptsDir .. "/AirplaneMode.sh"), { locked = true })
bind("XF86AudioPause", exec(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true })
bind("XF86AudioPlay", exec(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true })
bind("XF86AudioNext", exec(scriptsDir .. "/MediaCtrl.sh --nxt"), { locked = true })
bind("XF86AudioPrev", exec(scriptsDir .. "/MediaCtrl.sh --prv"), { locked = true })
bind("XF86AudioStop", exec(scriptsDir .. "/MediaCtrl.sh --stop"), { locked = true })

-- screenshots
bind(mainMod .. " + Print", exec(scriptsDir .. "/ScreenShot.sh --now"))
bind(mainMod .. " + SHIFT + Print", exec(scriptsDir .. "/ScreenShot.sh --area"))
bind(mainMod .. " + CTRL + Print", exec(scriptsDir .. "/ScreenShot.sh --in5"))
bind(mainMod .. " + CTRL + SHIFT + Print", exec(scriptsDir .. "/ScreenShot.sh --in10"))
bind("ALT + Print", exec(scriptsDir .. "/ScreenShot.sh --active"))
bind(mainMod .. " + SHIFT + S", exec(scriptsDir .. "/ScreenShot.sh --swappy"))

-- screen recording
bind(mainMod .. " + SHIFT + R", exec(UserScripts .. "/ScreenRecord.sh"))

-- resize / move / swap / focus
local directions = { left = { -50, 0 }, right = { 50, 0 }, up = { 0, -50 }, down = { 0, 50 } }
for dir, delta in pairs(directions) do
	bind(
		mainMod .. " + SHIFT + " .. dir,
		hl.dsp.window.resize({ x = delta[1], y = delta[2], relative = true }),
		{ repeating = true }
	)
	bind(mainMod .. " + CTRL + " .. dir, hl.dsp.window.move({ direction = dir }))
	bind(mainMod .. " + ALT + " .. dir, hl.dsp.window.swap({ direction = dir }))
	bind(mainMod .. " + " .. dir, hl.dsp.focus({ direction = dir }))
end

-- workspaces
bind(mainMod .. " + tab", hl.dsp.focus({ workspace = "m+1" }))
bind(mainMod .. " + SHIFT + tab", hl.dsp.focus({ workspace = "m-1" }))

bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }))
bind(mainMod .. " + U", hl.dsp.workspace.toggle_special())

-- code:10..19 are the number row keys 1..0
for i = 1, 10 do
	local key = "code:" .. (9 + i)
	bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
	bind(mainMod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end

bind(mainMod .. " + SHIFT + bracketleft", hl.dsp.window.move({ workspace = "-1" }))
bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }))
bind(mainMod .. " + CTRL + bracketleft", hl.dsp.window.move({ workspace = "-1", follow = false }))
bind(mainMod .. " + CTRL + bracketright", hl.dsp.window.move({ workspace = "+1", follow = false }))

bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
bind(mainMod .. " + period", hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + comma", hl.dsp.focus({ workspace = "e-1" }))

-- move / resize with mouse
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- random wallpaper (NOTE: SUPER+W is also bound to WallpaperSelect below, both run - same as before)
bind(mainMod .. " + W", exec("awww img $(find ~/Pictures/wallpapers -type f | shuf -n 1)"))

--------------------------
---- USER KEYBINDINGS ----
--------------------------
-- (was UserConfigs/UserKeybinds.conf)
bind(mainMod .. " + D", exec("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window"))
bind(mainMod .. " + B", exec('xdg-open "https://"'))
bind(mainMod .. " + F", exec(privateBrowser))
bind(mainMod .. " + ALT + F", exec(browser))
bind(mainMod .. " + A", exec("pkill rofi || true && ags -t 'overview'"))
bind(mainMod .. " + Return", exec(term))
bind(mainMod .. " + ALT + Return", exec(ghostty))
bind(mainMod .. " + E", exec(files))
bind(mainMod .. " + ALT + S", exec("steam"))
bind(mainMod .. " + H", exec(scriptsDir .. "/KeyHints.sh"))
bind(mainMod .. " + ALT + R", exec(scriptsDir .. "/Refresh.sh"))
bind(mainMod .. " + ALT + E", exec(scriptsDir .. "/RofiEmoji.sh"))
bind(mainMod .. " + S", exec(scriptsDir .. "/RofiSearch.sh"))
bind(mainMod .. " + ALT + O", exec(scriptsDir .. "/ChangeBlur.sh"))
bind(mainMod .. " + SHIFT + G", exec(scriptsDir .. "/GameMode.sh"))
bind(mainMod .. " + ALT + L", exec(scriptsDir .. "/ChangeLayout.sh"))
bind(mainMod .. " + ALT + V", exec(scriptsDir .. "/ClipManager.sh"))
bind(mainMod .. " + CTRL + R", exec(scriptsDir .. "/RofiThemeSelector.sh"))
bind(mainMod .. " + CTRL + SHIFT + R", exec("pkill rofi || true && " .. scriptsDir .. "/RofiThemeSelector-modified.sh"))

bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen())
bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
bind(mainMod .. " + SPACE", hl.dsp.window.float({ action = "toggle" }))

-- "All Float Mode" (was `workspaceopt allfloat`): toggles floating for every window on the
-- current workspace, and for windows opened there later
local allFloatRules = {}
bind(mainMod .. " + ALT + SPACE", function()
	local ws = hl.get_active_workspace()
	if not ws then
		return
	end

	local key = tostring(ws.id)
	local rule = allFloatRules[key]
	if not rule then
		rule =
			hl.window_rule({ name = "allfloat-ws-" .. key, match = { workspace = key }, float = true, enabled = false })
		allFloatRules[key] = rule
	end

	local enable = not rule:is_enabled()
	rule:set_enabled(enable)
	for _, w in ipairs(hl.get_workspace_windows(ws)) do
		hl.dispatch(hl.dsp.window.float({ action = enable and "set" or "unset", window = w }))
	end
end)

-- dropdown terminal
bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(term, { float = true, move = "15% 5%", size = "70% 60%" }))

-- desktop zoom
bind(mainMod .. " + ALT + mouse_down", function()
	local z = math.max(hl.get_config("cursor.zoom_factor"), 1)
	hl.config({ cursor = { zoom_factor = z * 2.0 } })
end)
bind(mainMod .. " + ALT + mouse_up", function()
	local z = math.max(hl.get_config("cursor.zoom_factor"), 1)
	hl.config({ cursor = { zoom_factor = math.max(z / 2.0, 1) } })
end)

bind(mainMod .. " + CTRL + ALT + B", exec("pkill -SIGUSR1 waybar"))
bind(mainMod .. " + CTRL + B", exec(scriptsDir .. "/WaybarStyles.sh"))
bind(mainMod .. " + ALT + B", exec(scriptsDir .. "/WaybarLayout.sh"))
bind(mainMod .. " + SHIFT + M", exec(UserScripts .. "/RofiBeats.sh"))
bind(mainMod .. " + W", exec(UserScripts .. "/WallpaperSelect.sh"))
bind(mainMod .. " + SHIFT + W", exec(UserScripts .. "/WallpaperEffects.sh"))
bind("CTRL + ALT + W", exec(UserScripts .. "/WallpaperRandom.sh"))
bind(mainMod .. " + CTRL + O", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }))
bind(mainMod .. " + SHIFT + K", exec(scriptsDir .. "/KeyBinds.sh"))
bind(mainMod .. " + SHIFT + A", exec(scriptsDir .. "/Animations.sh"))
bind(mainMod .. " + SHIFT + O", exec(UserScripts .. "/ZshChangeTheme.sh"))
bind("ALT_L + SHIFT_L", exec(scriptsDir .. "/SwitchKeyboardLayout.sh"), { locked = true, non_consuming = true })
bind(mainMod .. " + ALT + C", exec(UserScripts .. "/RofiCalc.sh"))
bind(mainMod .. " + C", exec("abacus --popup")) -- Abacus quick popup; press again to close

------------------------------
---- SCRIPT HELPERS       ----
------------------------------
-- `hyprctl keyword` does not work with a Lua config, so these replace it for the scripts.

-- scripts/ChangeLayout.sh
local layoutBinds = {}
function kool.toggle_layout()
	bindJ:set_enabled(false)
	bindK:set_enabled(false)
	for _, b in ipairs(layoutBinds) do
		b:set_enabled(false)
	end
	layoutBinds = {}

	if hl.get_config("general.layout") == "master" then
		hl.config({ general = { layout = "dwindle" } })
		layoutBinds = {
			bind(mainMod .. " + J", hl.dsp.window.cycle_next()),
			bind(mainMod .. " + K", hl.dsp.window.cycle_next({ next = false })),
			bind(mainMod .. " + O", hl.dsp.layout("togglesplit")),
		}
	else
		hl.config({ general = { layout = "master" } })
		layoutBinds = {
			bind(mainMod .. " + J", hl.dsp.layout("cyclenext")),
			bind(mainMod .. " + K", hl.dsp.layout("cycleprev")),
		}
	end
end

-- scripts/GameMode.sh (turning it off is a `hyprctl reload`)
local gameModeRule
function kool.game_mode_on()
	hl.config({
		animations = { enabled = false },
		decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 },
		general = { gaps_in = 0, gaps_out = 0, border_size = 1 },
	})
	gameModeRule = gameModeRule
		or hl.window_rule({
			name = "game-mode-opaque",
			match = { class = ".*" },
			opacity = "1 override 1 override 1 override",
		})
	gameModeRule:set_enabled(true)
end

----------------------
---- WINDOW RULES ----
----------------------
-- (was UserConfigs/WindowRules.conf)
local function rule(match, effects)
	effects.match = match
	return hl.window_rule(effects)
end

-- tags
local tags = {
	{ "browser", { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" } },
	{ "browser", { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" } },
	{ "browser", { class = "^(chrome-.+-Default)$" } },
	{ "browser", { class = "^([Cc]hromium)$" } },
	{ "browser", { class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" } },
	{ "browser", { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" } },
	{ "browser", { class = "^([Tt]horium-browser|[Cc]achy-browser)$" } },
	{ "browser", { class = "^(zen-alpha|zen)$" } },
	{ "notif", { class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$" } },
	{ "KooL_Cheat", { title = "^(KooL Quick Cheat Sheet)$" } },
	{ "KooL_Settings", { title = "^(KooL Hyprland Settings)$" } },
	{ "KooL-Settings", { class = "^(nwg-displays|nwg-look)$" } },
	{ "terminal", { class = "^(Alacritty|kitty|kitty-dropterm)$" } },
	{ "email", { class = "^([Tt]hunderbird|org.gnome.Evolution)$" } },
	{ "email", { class = "^(eu.betterbird.Betterbird)$" } },
	{ "projects", { class = "^(codium|codium-url-handler|VSCodium)$" } },
	{ "projects", { class = "^(VSCode|code-url-handler)$" } },
	{ "projects", { class = "^(jetbrains-.+)$" } },
	{ "screenshare", { class = "^(com.obsproject.Studio)$" } },
	{ "im", { class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" } },
	{ "im", { class = "^([Ff]erdium)$" } },
	{ "im", { class = "^([Ww]hatsapp-for-linux)$" } },
	{ "im", { class = "^(ZapZap|com.rtosta.zapzap)$" } },
	{ "im", { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" } },
	{ "im", { class = "^(teams-for-linux)$" } },
	{ "games", { class = "^(gamescope)$" } },
	{ "games", { class = "^(steam_app_\\d+)$" } },
	{ "gamestore", { class = "^([Ss]team)$" } },
	{ "gamestore", { title = "^([Ll]utris)$" } },
	{ "gamestore", { class = "^(com.heroicgameslauncher.hgl)$" } },
	{ "file-manager", { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$" } },
	{ "file-manager", { class = "^(app.drey.Warp)$" } },
	{ "wallpaper", { class = "^([Ww]aytrogen)$" } },
	{ "multimedia", { class = "^([Aa]udacious)$" } },
	{ "multimedia_video", { class = "^([Mm]pv|vlc)$" } },
	{ "settings", { title = "^(ROG Control)$" } },
	{ "settings", { class = "^(wihotspot(-gui)?)$" } },
	{ "settings", { class = "^([Bb]aobab|org.gnome.[Bb]aobab)$" } },
	{ "settings", { class = "^(gnome-disks|wihotspot(-gui)?)$" } },
	{ "settings", { title = "(Kvantum Manager)" } },
	{ "settings", { class = "^(file-roller|org.gnome.FileRoller)$" } },
	{ "settings", { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" } },
	{ "settings", { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" } },
	{ "settings", { class = "^(qt5ct|qt6ct|[Yy]ad)$" } },
	{ "settings", { class = "(xdg-desktop-portal-gtk)" } },
	{ "settings", { class = "^(org.kde.polkit-kde-authentication-agent-1)$" } },
	{ "settings", { class = "^([Rr]ofi)$" } },
	{
		"viewer",
		{ class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$" },
	},
	{ "viewer", { class = "^(evince)$" } },
	{ "viewer", { class = "^(eog|org.gnome.Loupe)$" } },
}
for _, t in ipairs(tags) do
	rule(t[2], { tag = "+" .. t[1] })
end

rule({ tag = "multimedia_video*" }, { no_blur = true })
rule({ tag = "multimedia_video*" }, { opacity = "1.0" })

-- center
rule({ tag = "KooL_Cheat*" }, { center = true })
rule({ class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" }, { center = true })
rule({ title = "^(ROG Control)$" }, { center = true })
rule({ tag = "KooL-Settings*" }, { center = true })
rule({ title = "^(Keybindings)$" }, { center = true })
rule({ class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }, { center = true })
rule({ class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, { center = true })
rule({ class = "^([Ff]erdium)$" }, { center = true })

rule({ title = "^(Picture-in-Picture)$" }, { move = "72% 7%" })
rule({ fullscreen = true }, { idle_inhibit = "fullscreen" })

-- workspaces
rule({ tag = "email*" }, { workspace = "1" })
rule({ class = "^([Kk]itty|com\\.mitchellh\\.ghostty|ghostty)$" }, { workspace = "1" })
rule({ tag = "browser*" }, { workspace = "2" })
rule({ class = "^(privateBrowser)$" }, { workspace = "4" })
rule({ tag = "gamestore*" }, { workspace = "5" })
rule({ class = "^(com.heroicgameslauncher.hgl)$" }, { workspace = "6" })
rule({ tag = "im*" }, { workspace = "7" })
rule({ tag = "games*" }, { workspace = "8" })
rule({ tag = "screenshare*" }, { workspace = "4 silent" })
rule({ class = "^(virt-manager)$" }, { workspace = "6 silent" })
rule({ class = "^(.virt-manager-wrapped)$" }, { workspace = "6 silent" })
rule({ tag = "multimedia*" }, { workspace = "9 silent" })

-- float
rule({ tag = "KooL_Cheat*" }, { float = true })
rule({ tag = "wallpaper*" }, { float = true })
rule({ tag = "settings*" }, { float = true })
rule({ tag = "viewer*" }, { float = true })
rule({ tag = "KooL-Settings*" }, { float = true })
rule({ class = "([Zz]oom|onedriver|onedriver-launcher)$" }, { float = true })
rule({ class = "(org.gnome.Calculator)", title = "(Calculator)" }, { float = true })
rule({ class = "^(mpv|com.github.rafostar.Clapper)$" }, { float = true })
rule({ class = "^([Qq]alculate-gtk)$" }, { float = true })
rule({ class = "^([Ff]erdium)$" }, { float = true })
rule({ title = "^(Picture-in-Picture)$" }, { float = true })
rule({ title = "^(Authentication Required)$" }, { float = true, center = true })
rule({ class = "(codium|codium-url-handler|VSCodium)", title = "negative:(.*codium.*|.*VSCodium.*)" }, { float = true })
rule({ class = "^(com.heroicgameslauncher.hgl)$", title = "negative:(Heroic Games Launcher)" }, { float = true })
rule({ class = "^([Ss]team)$", title = "negative:^([Ss]team)$" }, { float = true })
rule({ class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" }, { float = true })
rule({ title = "^(Add Folder to Workspace)$" }, { float = true, size = "70% 60%", center = true })
rule({ title = "^(Save As)$" }, { float = true, size = "70% 60%", center = true })
rule({ initial_title = "(Open Files)" }, { float = true, size = "70% 60%" })
rule({ title = "^(SDDM Background)$" }, { float = true, center = true, size = "16% 12%" })
-- Abacus calculator: both windows float; the quick popup also follows you across
-- workspaces and keeps the keyboard until it is closed (Esc, or SUPER+C again)
rule({ class = "^(abacus)$" }, { float = true, center = true })
rule({ class = "^(abacus)$", title = "^(Abacus Quick)$" }, { pin = true, stay_focused = true })

-- opacity (active inactive)
rule({ tag = "browser*" }, { opacity = "0.9 0.7" })
rule({ tag = "projects*" }, { opacity = "0.9 0.8" })
rule({ tag = "im*" }, { opacity = "0.94 0.86" })
rule({ tag = "multimedia*" }, { opacity = "0.94 0.86" })
rule({ tag = "file-manager*" }, { opacity = "0.9 0.8" })
rule({ tag = "terminal*" }, { opacity = "0.8 0.7" })
rule({ tag = "settings*" }, { opacity = "0.8 0.7" })
rule({ tag = "viewer*" }, { opacity = "0.82 0.75" })
rule({ tag = "wallpaper*" }, { opacity = "0.9 0.7" })
rule({ class = "^(gedit|org.gnome.TextEditor|mousepad)$" }, { opacity = "0.8 0.7" })
rule({ class = "^(deluge)$" }, { opacity = "0.9 0.8" })
rule({ class = "^(im.riot.Riot)$" }, { opacity = "0.9 0.8" })
rule({ class = "^(seahorse)$" }, { opacity = "0.9 0.8" })
rule({ title = "^(Picture-in-Picture)$" }, { opacity = "0.95 0.75" })

-- size
rule({ tag = "KooL_Cheat*" }, { size = "65% 90%" })
rule({ tag = "wallpaper*" }, { size = "70% 70%" })
rule({ tag = "settings*" }, { size = "70% 70%" })
rule({ class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, { size = "60% 70%" })
rule({ class = "^([Ff]erdium)$" }, { size = "60% 70%" })

-- picture-in-picture
rule({ title = "^(Picture-in-Picture)$" }, { pin = true, keep_aspect_ratio = true })

rule({ tag = "games*" }, { no_blur = true })

-- layer rules
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true, ignore_alpha = 0 })
