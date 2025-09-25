--- Conky config script

-- Conky does not add our config directory to lua's PATH, so we do it manually
local script_dir = debug.getinfo(1, 'S').source:match("^@(.*/)") or "./"
package.path = script_dir .. "../?.lua;" .. package.path

-- We need to know the current file so that we can tell conky to load itlo
local rc_path = debug.getinfo(1, 'S').source:match("[^/]*.lua$")

-- load a theme as default
-- current_theme = require('src/themes/dimensions')
current_theme = require('src/themes/pcore2')

local bubbles = require('src/bubbles')
local data  = require('src/data')
local util = require('src/util')
local ch = require('src/cairo_helpers')
local core  = require('src/widgets/core')
local containers  = require('src/widgets/containers')
local cpu   = require('src/widgets/cpu')
local drive = require('src/widgets/drive')
local gpu   = require('src/widgets/gpu')
local images = require('src/widgets/images')
local mem   = require('src/widgets/memory')
local net   = require('src/widgets/network')
local text  = require('src/widgets/text')

local Frame, Filler, Rows, Columns, Float, Stack, Block = containers.Frame, containers.Filler,
                                          containers.Rows, containers.Columns, containers.Float, containers.Stack, containers.Block
local CpuCombo, CpuFrequencies, CpuTop = cpu.CpuCombo, cpu.CpuFrequencies, cpu.CpuTop
local Drive = drive.Drive
local Gpu, GpuTop = gpu.Gpu, gpu.GpuTop
local StaticImage, RandomImage = images.StaticImage, images.RandomImage
local MemoryGrid, MemTop = mem.MemoryGrid, mem.MemTop
local Network = net.Network
local ConkyText, StaticText, TextLine = text.ConkyText, text.StaticText, text.TextLine

-- lua 5.1 to 5.3 compatibility
local unpack = unpack or table.unpack  -- luacheck: read_globals unpack table


local conkyrc = conky or {}


local script_config = {
    lua_load = script_dir .. rc_path,

    alignment = 'top_left',
    gap_x = 0,
    gap_y = 100,
    minimum_width = 140,
    maximum_width = 140,
    minimum_height = 210,
    xinerama_head = 0,

    -- font --
    font = 'SUSE:pixelsize=10',
    draw_shades = true,
    default_shade_color = 'black',

    -- colors --
    own_window_colour = '131313',
    own_window_argb_visual = true,
    own_window_argb_value = 180,
    default_color = 'fafafa',
}

local core_config = require('src/config/core')
local wm_config = {}

if os.getenv("DESKTOP") == "Enlightenment" then
    wm_config = require('src/config/enlightenment')
else
    wm_config = require('src/config/awesome')
end

local tmp_config = util.merge_table(core_config, wm_config)
local config = util.merge_table(tmp_config, script_config)

conkyrc.config = config

-----------------
----- START -----
-----------------

conkyrc.text = [[ ]]

--- Called once on startup to initialize widgets.
-- @treturn widget.Renderer
function bubbles.setup()
    
    -- these look better with different color orders
    local title_font_dimensions = {color=current_theme.highlight_color,font_family="SUSE", font_size=26, align=CAIRO_TEXT_ALIGN_CENTER, border_width=0.8, border_color=current_theme.temperature_colors[3]}
    local title_font_pcore2 = {color=current_theme.temperature_colors[2],font_family="SUSE", font_size=26, align=CAIRO_TEXT_ALIGN_CENTER, border_width=0.8, border_color=current_theme.temperature_colors[1]}


    local root = 
    Frame(Rows{
            -- StaticText("Dimensions", title_font_dimensions),
            StaticText("pcore2", title_font_pcore2),
            CpuCombo{cores=16, inner_radius=25, mid_radius=57, outer_radius=68, gap=6, grid=5},
            Filler({height=10}),
            CpuTop({}),
            Filler({})
            }, {
                -- T R B L
                padding = {10, 20, 30, 10},
            })

    return core.Renderer{root=root,
                           width=conkyrc.config.minimum_width,
                           height=conkyrc.config.minimum_height}
end
