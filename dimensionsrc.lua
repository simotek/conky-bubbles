--- Conky config script

-- Conky does not add our config directory to lua's PATH, so we do it manually
local script_dir = debug.getinfo(1, 'S').source:match("^@(.*/)") or "./"
package.path = script_dir .. "../?.lua;" .. package.path

-- load polycore theme as default
current_theme = require('src/themes/dimensions')

local polycore = require('src/polycore')
local data  = require('src/data')
local util = require('src/util')
local ch = require('src/cairo_helpers')
local core  = require('src/widgets/core')
local cpu   = require('src/widgets/cpu')
local drive = require('src/widgets/drive')
local gpu   = require('src/widgets/gpu')
local images = require('src/widgets/images')
local mem   = require('src/widgets/memory')
local net   = require('src/widgets/network')
local text  = require('src/widgets/text')

local Frame, Filler, Rows, Columns, Float, Stack = core.Frame, core.Filler,
                                          core.Rows, core.Columns, core.Float, core.Stack
local CpuCombo, CpuFrequencies, CpuTop = cpu.CpuCombo, cpu.CpuFrequencies, cpu.CpuTop
local Drive = drive.Drive
local Gpu, GpuTop = gpu.Gpu, gpu.GpuTop
local StaticImage, RandomImage = images.StaticImage, images.RandomImage
local MemoryGrid, MemTop = mem.MemoryGrid, mem.MemTop
local Network = net.Network
local ConkyText, StaticText, TextLine = text.ConkyText, text.StaticText, text.TextLine

-- Draw debug information
DEBUG = false


local conkyrc = conky or {}

-- Todo auto detect this.
local screen_width = 2560

script_config = {
    lua_load = script_dir .. "dimensions.lua",

    alignment = 'top_left',
    gap_x = 0,
    gap_y = 100,
    minimum_width = screen_width,
    maximum_width = screen_width,
    minimum_height = 350,
    xinerama_head = 3,

    -- font --
    font = 'Ubuntu:pixelsize=10',
    draw_shades = true,
    default_shade_color = 'black',

    -- colors --
    own_window_colour = '131313',
    own_window_argb_visual = true,
    own_window_argb_value = 0,
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

core_config = require('src/config/core')

if os.getenv("DESKTOP") == "Enlightenment" then
    wm_config = require('src/config/enlightenment')
else
    wm_config = require('src/config/awesome')
end

tmp_config = util.merge_table(core_config, wm_config)
config = util.merge_table(tmp_config, script_config)

conkyrc.config = config

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

    local root = 
    Stack{
        Float(StaticText("openSUSE",{color=current_theme.highlight_color,font_family="SUSE", font_size=34}), {x=200, y=5}),
        Float(StaticText("Linux",{font_family="SUSE", font_size=34}), {x=360, y=5}),
        Float(StaticText("Have alot of fun.",{font_family="SUSE Light", font_size=14}), {x=450, y=25}),
        Float(Frame(Columns{
            Columns({
                StaticImage("assets/dimensions/system-icon.png", {fixed_size=true})
            }),
            Rows{
                Filler{},
                CpuCombo{cores=16, inner_radius=25, mid_radius=45, outer_radius=62, gap=6, grid=5},
                Filler{},
            },
            Filler{width=30},
            Rows{
                CpuFrequencies{cores=6, min_freq=0.75, max_freq=4.3},
                Filler{height=5},
                CpuTop({}),
            },
            Filler{width=30},
            Rows{
                MemoryGrid{rows=8},
                Filler{height=11},
                MemTop({}),
            },
            Filler{width=30},
            Rows{
                Filler{height=26},
                Network{interface="enp0s13f0u1u4u4", downspeed=5 * 1024, upspeed=1024},
            },
            Filler{width=30},
            Rows({Gpu(),
            GpuTop({})}),
            Filler{width=30},
            --StaticImage("/home/simon/Pictures/grav.png", {}),
            --Filler{width=30},
            RandomImage("/home/simon/Pictures/PhotoFrame/", {}),
            Rows{
                Drive("system-root"),
                Filler{height=-9},
                Drive("system-home"),
                Filler{height=-9},
            },
            }, {
                background_image="assets/dimensions/bg_2650.png",
                background_image_alpha=0.5,
                border_color={0.8, 1, 1, 0.05},
                border_width = 1,
                padding = {20, 20, 20, 10},
            }),
        {x=0, y=50, width=screen_width, height=230}),
        Float(ConkyText("${time %H:%M:%S}",{font_family="SUSE Thin", font_size=120}), {x=1600, y=210}),
        Float(ConkyText("${time %d}",{color=current_theme.highlight_color, font_family="SUSE Light", font_size=42}), {x=2100, y=231}),
        Float(ConkyText("${time  %B} ${time %Y}",{font_family="SUSE Thin", font_size=32}), {x=2160, y=237}),
        Float(ConkyText("${time %A}",{font_family="SUSE Thin", font_size=48}), {x=2100, y=280}),
    }

    return core.Renderer{root=root,
                           width=conkyrc.config.minimum_width,
                           height=conkyrc.config.minimum_height}
end
