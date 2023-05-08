--- Conky config script

-- Conky does not add our config directory to lua's PATH, so we do it manually
local script_dir = debug.getinfo(1, 'S').source:match("^@(.*/)") or "./"
package.path = script_dir .. "../?.lua;" .. package.path

-- load polycore theme as default
current_theme = require('src/themes/dimensions')

local polycore = require('src/polycore')
local data  = require('src/data')
local ch = require('src/cairo_helpers')
local core  = require('src/widgets/core')
local cpu   = require('src/widgets/cpu')
local drive = require('src/widgets/drive')
local gpu   = require('src/widgets/gpu')
local mem   = require('src/widgets/memory')
local net   = require('src/widgets/network')
local text  = require('src/widgets/text')

local Frame, Filler, Rows, Columns = core.Frame, core.Filler,
                                          core.Rows, core.Columns
local Cpu, CpuFrequencies = cpu.Cpu, cpu.CpuFrequencies
local Drive = drive.Drive
local Gpu, GpuTop = gpu.Gpu, gpu.GpuTop
local MemoryGrid = mem.MemoryGrid
local Network = net.Network
local ConkyText, TextLine = text.ConkyText, text.TextLine

-- Draw debug information
DEBUG = false


local conkyrc = conky or {}
conkyrc.config = {
    lua_load = script_dir .. "dimensions.lua",

    lua_startup_hook = "conky_setup",
    lua_draw_hook_pre = "conky_paint_background",
    lua_draw_hook_post = "conky_update",

    update_interval = 1,

    -- enlightenment wm --
    own_window = true,
    own_window_class = 'conky',
    own_window_type = 'normal',
    own_window_transparent = false,
    own_window_hints = 'undecorated,sticky,below,skip_taskbar,skip_pager',

    double_buffer = true,
    background = false,

    alignment = 'top_left',
    gap_x = 0,
    gap_y = 0,
    minimum_width = 1600,
    maximum_width = 1600,
    minimum_height = 170,

    draw_shades = false,
    draw_outline = false,
    draw_borders = false,
    border_width = 0,
    border_inner_margin = 0,
    border_outer_margin = 0,

    top_cpu_separate = true,
    top_name_width = 10,
    no_buffers = true,  -- include buffers in easyfree memory?
    cpu_avg_samples = 2,
    net_avg_samples = 1,

    -- font --
    use_xft = true,  -- Use Xft (anti-aliased font and stuff)
    font = 'Ubuntu:pixelsize=10',
    override_utf8_locale = true,
    xftalpha = 0,  -- Alpha of Xft font. Must be a value at or between 1 and 0.
    draw_shades = true,
    default_shade_color = 'black',
    draw_borders = false,
    draw_outline = false,

    -- colors --
    own_window_colour = '131313',
    own_window_argb_visual = true,
    own_window_argb_value = 180,
    default_color = 'fafafa',
    color0 = '337777',  -- titles
    color1 = 'b9b9b7',  -- secondary text color
    color2 = 'bb5544',  -- high temperature warning color

    -- drives: name dir --
    template5 = [[
${if_mounted \2}
${goto 652}${font Ubuntu:pixelsize=11:bold}${color0}· \1 ·#
${voffset 20}#
${goto 652}${color1}${font Ubuntu:pixelsize=10}${fs_used \2}  /  ${fs_size \2}#
${alignr 20}${fs_used_perc \2}%$font$color#
$endif]],
}

-----------------
----- START -----
-----------------

conkyrc.text = [[
${voffset 10}#
${alignc 312}${font TeXGyreChorus:pixelsize=20:bold}#
${color ffffff}P${color ddffff}o${color bbeeee}l${color 99eeee}y#
${color 77eeee}c${color 55eeee}o${color 44eeee}r${color 33eeee}e#
$color$font
#${alignc 320}${font Courier new:pixelsize=20}${color ccffff}Polycore${color}$font
${font Ubuntu:pixelsize=11:bold}${color0}#
${voffset -14}${alignc  247}[ mem ]
${voffset -14}${alignc  160}[ cpu ]
${voffset -14}${alignc    0}[ gpu ]
${voffset -14}${alignc -160}[ net ]
${voffset -14}${alignc -310}[ dev ]
$color$font${voffset 26}#
#
### top ###
${color1}
${goto 180}${top name 1}${alignr 490}${top cpu 1} %
${goto 180}${top name 2}${alignr 490}${top cpu 2} %
${goto 180}${top name 3}${alignr 490}${top cpu 3} %
${goto 180}${top name 4}${alignr 490}${top cpu 4} %
${goto 180}${top name 5}${alignr 490}${top cpu 5} %
${voffset -92}#
#
### net ###
${goto 495}${color1}Down$color${alignr 180}${downspeed enp0s31f6}
${goto 495}${color1}Total$color${alignr 180}${totaldown enp0s31f6}
${voffset 29}#
${goto 495}${color1}Up$color${alignr 180}${upspeed enp0s31f6}
${goto 495}${color1}Total$color${alignr 180}${totalup enp0s31f6}
${voffset -88}#
#
### drives ###
${template5 root /}#
${voffset 5}#
${template5 home /home}#
${voffset 5}#
]]

--- Called once on startup to initialize widgets.
-- @treturn widget.Renderer
function polycore.setup()

    local root = Frame(Columns{
        Rows{
            Filler{},
            Cpu{cores=6, inner_radius=28, gap=5, outer_radius=57},
            Filler{},
        },
        Filler{width=10},
        MemoryGrid{columns=5},
        Filler{width=20},
        Rows{
            CpuFrequencies{cores=6, min_freq=0.75, max_freq=4.3},
            Filler{height=10},
            Columns{ConkyText("${top name 1}", {}), Filler{width=10}, ConkyText("${top cpu 1} %", {align="right"})},
            Columns{ConkyText("${top name 2}", {}), Filler{width=10}, ConkyText("${top cpu 2} %", {align="right"})},
            Columns{ConkyText("${top name 3}", {}), Filler{width=10}, ConkyText("${top cpu 3} %", {align="right"})},
            Columns{ConkyText("${top name 4}", {}), Filler{width=10}, ConkyText("${top cpu 4} %", {align="right"})},
            Columns{ConkyText("${top name 5}", {}), Filler{width=10}, ConkyText("${top cpu 5} %", {align="right"})},
        },
        Filler{width=30},
        Rows{
            Filler{height=5},
            --Gpu(),
            Filler{height=5},
            --Columns{Filler{width=10},ConkyText("${top cpu 1} %",{align="right"})}
            
            --Columns{ConkyText("${top name 1}"), Filler{width=10},ConkyText("${top cpu 1} %",{align="right"})}


            --GpuTop{lines=5, color=secondary_text_color},
        },
        Filler{width=30},
        Rows{
            Filler{height=26},
            Network{interface="enp34s0u1u3u4", downspeed=5 * 1024, upspeed=1024},
        },
        Filler{width=30},
        Rows{
            Drive("/dev/system/root"),
            Filler{height=-9},
            Drive("/dev/system/home"),
            Filler{height=-9},
        },
    }, {
        border_color={0.8, 1, 1, 0.05},
        border_width = 1,
        padding = {40, 20, 20, 10},
    })
    return core.Renderer{root=root,
                           width=conkyrc.config.minimum_width,
                           height=conkyrc.config.minimum_height}
end
