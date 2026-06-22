--- Conky entry point script

-- Conky does not add our config directory to lua's PATH, so we do it manually
local script_dir = debug.getinfo(1, 'S').source:match("^@(.*/)") or "./"
package.path = script_dir .. "../?.lua;" .. package.path
-- We need to know the current file so that we can tell conky to load itlo
local rc_path = debug.getinfo(1, 'S').source:match("[^/]*.lua$"):gsub("@","")


-- load a theme
current_theme = require('src/themes/dimensions')

-- load required libraries
local bubbles = require('src/bubbles')
local ch = require('src/cairo_helpers')
local cl = require('src/config_loader')
local data = require('src/data')
local util = require('src/util')
local widgets = require('src/widgets/widgets')

-- lua 5.1 to 5.3 compatibility
local unpack = unpack or table.unpack  -- luacheck: read_globals unpack table

-- load widgets we are using
local Filler, Rows, Columns, Float = widgets.containers.Filler,
      widgets.containers.Rows, widgets.containers.Columns, widgets.containers.Float
local CpuCombo, CpuFrequencies, CpuTop = widgets.cpu.CpuCombo, widgets.cpu.CpuFrequencies, widgets.cpu.CpuTop
local DriveList = widgets.drive.DriveList
local StaticImage = widgets.images.StaticImage
local MemoryGrid, MemTop = widgets.mem.MemoryGrid, widgets.mem.MemTop
local Network = widgets.net.Network
local ConkyText, StaticText = widgets.text.ConkyText, widgets.text.StaticText

-- Draw debug information
DEBUG = false

local conkyrc = conky or {}

local screen_height = util.screen_height()

local config_width = 280
local config_height = screen_height - 68 - 48

local script_config = {
    lua_load = script_dir .. rc_path,

    -- positioning --
    alignment = 'top_left',
    gap_x = 0,
    gap_y = 68,
    minimum_width = config_width,
    maximum_width = config_width,
    minimum_height = config_height,
    maximum_height = config_height,
    xinerama_head = 0,

    -- colors --
    own_window_colour = 'D4131313',
}

-- Merge our config with the rest
conkyrc.config = cl.load_config(script_config)

-----------------
----- START -----
-----------------

-- we don't draw any text via the native conky handler
conkyrc.text = [[ ]]

--- Called once on startup to initialize widgets.
-- @treturn core.Renderer
function bubbles.setup()

    local title_font = {color=current_theme.temperature_colors[2],font_family="SUSE", font_size=32, align=CAIRO_TEXT_ALIGN_CENTER, border_width=0.8, border_color="224477AA"}
    local centered_font = {color=current_theme.secondary_text_color,font_family=current_theme.default_font_family, font_size=current_theme.default_font_size, align=CAIRO_TEXT_ALIGN_CENTER}
    local header_font = {color=current_theme.header_color,font_family=current_theme.default_font_family, font_size=current_theme.header_font_size, border_width=0.6, border_color="22447788"}
    local status_font = {color=current_theme.secondary_text_color,font_family=current_theme.default_font_family, font_size=current_theme.default_font_size, align=CAIRO_TEXT_ALIGN_RIGHT}

    local block_space = 12

    local widg = {
        StaticText("Bubbles", title_font),
        Filler({height=10}),
        ConkyText("${time %d.%m.%Y}", centered_font),
        ConkyText("${time %H:%M}", centered_font),-- see above
        Filler({height=8}),
        CpuCombo({cores=data.cpu_cores(), inner_radius=25, mid_radius=57, outer_radius=68, gap=6, grid=5}),
        Filler({height=7}),
        CpuFrequencies({cores=data.cpu_cores(), min_freq=0.75, max_freq=4.3}),
        Filler({height=10}),
        Columns({StaticText("[   top   ]", header_font), ConkyText("${freq_g 1}%", status_font)}),
        CpuTop({}),
        Filler{height=block_space},

        -- See also widget.MemoryBar
        Columns({StaticText("[   mem   ]", header_font), ConkyText("${memperc}%", status_font)}),
        Filler({height=5}),
        MemoryGrid({rows=5}),
        Filler({height=5}),
        MemTop({}),
        Filler({height=block_space}),

        StaticText("[   net   ]", header_font),
        -- Adjust the interface name for your system. Run `ifconfig` to find
        -- out yours. Common names are "eth0" and "wlan0".
        Network({downspeed=5 * 1024, upspeed=1024,
                       graph_height=22}),
        Filler({height=block_space}),
        DriveList(),
        Filler({height=400}),
        StaticImage("/home/simon/src/devel/conky-bubbles/assets/pcore2/9blocks.png",{})
    }
    local root = Float(Rows(widg), {x=40, y=20, width=config_width-40, height=800})
    return widgets.core.Renderer{root=root,
                           width=config_width,
                           height=config_height}
end
