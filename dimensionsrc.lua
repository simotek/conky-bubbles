--- Conky config script

-- Conky does not add our config directory to lua's PATH, so we do it manually
local script_dir = debug.getinfo(1, 'S').source:match("^@(.*/)") or "./"
package.path = script_dir .. "../?.lua;" .. package.path

-- We need to know the current file so that we can tell conky to load itlo
local rc_path = debug.getinfo(1, 'S').source:match("[^/]*.lua$"):gsub("@","")

print (rc_path)

-- load a theme as default
current_theme = require('src/themes/dimensions')

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

-- Draw debug information
local DEBUG = false


local conkyrc = conky or {}

-- Todo auto detect this.
local screen_width = util.screen_width()

local script_config = {
    lua_load = script_dir .. rc_path,

    alignment = 'top_left',
    gap_x = 0,
    gap_y = 100,
    minimum_width = screen_width,
    maximum_width = screen_width,
    minimum_height = 350,
    xinerama_head = 0,

    -- font --
    font = 'SUSE:pixelsize=10',
    draw_shades = true,
    default_shade_color = 'black',

    -- colors --
    own_window_colour = '131313',
    own_window_argb_visual = true,
    own_window_argb_value = 0,
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

local block_space = 15
local main_height = 250

local block_args = {padding = {13, 7, 15}, spacing=1}

--- Called once on startup to initialize widgets.
-- @treturn widget.Renderer
function bubbles.setup()

    local title_gradient = cairo_pattern_create_mesh()
    cairo_mesh_pattern_begin_patch(title_gradient)
    cairo_mesh_pattern_line_to(title_gradient, 00, 10)
    cairo_mesh_pattern_line_to(title_gradient, 160, 5)
    cairo_mesh_pattern_line_to(title_gradient, 150, 55)
    cairo_mesh_pattern_line_to(title_gradient, -10, 65)
    cairo_mesh_pattern_line_to(title_gradient, 00, 10)

    cairo_mesh_pattern_set_corner_color_rgba(title_gradient, 0, unpack(ch.convert_string_to_rgba(current_theme.temperature_colors[1])))
    cairo_mesh_pattern_set_corner_color_rgba(title_gradient, 1, unpack(ch.convert_string_to_rgba(current_theme.temperature_colors[4])))
    cairo_mesh_pattern_set_corner_color_rgba(title_gradient, 2, unpack(ch.convert_string_to_rgba(current_theme.temperature_colors[1])))
    cairo_mesh_pattern_set_corner_color_rgba(title_gradient, 3, unpack(ch.convert_string_to_rgba(current_theme.temperature_colors[6])))
    cairo_mesh_pattern_end_patch(title_gradient)


    local root = 
    Stack{
        -- Background
        Float(Frame(Filler{}, {
                background_image="assets/dimensions/bg_2650_inner.png",
                background_image_alpha=0.7,
                border_color={0.8, 1, 1, 0.05},
                border_width = 1,
                -- T R B L
                padding = {0, 20, 0, 20},
            }),
        {x=0, y=50, width=screen_width, height=main_height}),
        Float(Frame(Filler{},{
                background_image="assets/dimensions/bg_2650_frame.png",
                background_image_alpha=1.0,
                border_color={0.8, 1, 1, 0.05},
                border_width = 1,
                padding = {10, 10, 25, 25},
            }),
        {x=0, y=50, width=screen_width, height=main_height}),
        Float(StaticText("openSUSE",{pattern=title_gradient,font_family="SUSE", font_size=34, border_width=0.9, border_color=current_theme.temperature_colors[2]}), {x=200, y=5}),
        Float(StaticText("Linux",{font_family="SUSE", font_size=34, border_width=0.8, border_color="55555588"}), {x=360, y=5}),
        Float(StaticText("たくさん楽しんでください",{font_family="Noto Sans CJK JP", font_size=16, border_width=0.8, border_color="55555588"}), {x=450, y=20}), -- {x=450, y=25}
        Float(Frame(Columns{
            Block("[ SYSTEM ]", "${uptime_short}",
                {
                 ConkyText("Processes :  ${processes}  ( ${running_processes} running )",{}),
                 ConkyText("Threads :  ${running_threads}",{}),
                 ConkyText("Connections :  ${tcp_portmon 1 65535 count}",{}),
                 Filler{},Filler{},Filler{}},
            block_args),
            Frame(Filler{width=block_space},{
                background_image="assets/dimensions/div.png",
                background_image_alpha=1.0,
            }),
            Block("[ CPU ]", "${cpu 0}%",
                {CpuCombo{cores=16, inner_radius=25, mid_radius=57, outer_radius=68, gap=6, grid=5},
                Filler{}},
            block_args),
            Frame(Filler{width=block_space},{
                background_image="assets/dimensions/div.png",
                background_image_alpha=1.0,
            }),
            Block("[ FREQ ]", "${freq_g 0}GHz",
                { CpuFrequencies{cores=6, min_freq=0.75, max_freq=4.3},
                Filler{height=6},
                CpuTop({})}, 
            block_args),
            Frame(Filler{width=block_space},{
                background_image="assets/dimensions/div.png",
                background_image_alpha=1.0,
            }),
            Block("[ MEM ]", "${memperc}%",
                {MemoryGrid{rows=9},
                Filler{height=12},
                MemTop({})},
            block_args),
            Frame(Filler{width=block_space},{
                background_image="assets/dimensions/div.png",
                background_image_alpha=1.0,
            }),
            Block("[ GPU ]", "${nvidia gpufreq} MHz", 
                {Gpu(),
                GpuTop({})},
            block_args),
            Frame(Filler{width=block_space},{
                background_image="assets/dimensions/div.png",
                background_image_alpha=1.0,
            }),
            Block("[ NET ]", "",
                {Network{interface="enp0s13f0u1u4u4", downspeed=5 * 1024, upspeed=1024}},
            block_args),
            Frame(Filler{width=block_space},{
                background_image="assets/dimensions/div_left.png",
                background_image_alpha=1.0,
            }),
            Frame(RandomImage("/home/simon/Pictures/PhotoFrame/", {}),
                {background_color="1b1b1b", expand=true, margin={12,0,12}, padding=8}),
            Frame(Filler{width=block_space},{
                background_image="assets/dimensions/div_right.png",
                background_image_alpha=1.0,
            }),
            Block("[ DISK ]", "",
                {drive.Drive("/", {device="nvme0n1p1", physical_device="nvme0n1"}),
                drive.Drive("/home", {device="nvme0n1p2", physical_device="nvme0n1"})},
            block_args),
            }, {
                -- T R B L
                padding = {0, 20, 0, 20},
            }),
        {x=0, y=50, width=screen_width, height=main_height}),
        Float(ConkyText("${time %H:%M:%S}",{font_family="SUSE Thin", font_size=120, border_width=0.8, border_color="55555588"}), {x=screen_width-960, y=main_height-25}),
        Float(ConkyText("${time %d}",{color=current_theme.highlight_color, font_family="SUSE Light", font_size=42, border_width=0.8, border_color="55555588"}), {x=screen_width-460, y=main_height-25+21}),
        Float(ConkyText("${time  %B} ${time %Y}",{font_family="SUSE Thin", font_size=32, border_width=0.8, border_color="55555588"}), {x=screen_width-400, y=main_height-25+27}),
        Float(ConkyText("${time %A}",{font_family="SUSE Thin", font_size=48, border_width=0.8, border_color="55555588"}), {x=screen_width-460, y=main_height-25+70}),
    }

    return core.Renderer{root=root,
                           width=conkyrc.config.minimum_width,
                           height=conkyrc.config.minimum_height}
end
