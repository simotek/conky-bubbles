--- Conky config script

-- Conky does not add our config directory to lua's PATH, so we do it manually
local script_dir = debug.getinfo(1, 'S').source:match("^@(.*/)") or "./"
package.path = script_dir .. "../?.lua;" .. package.path

-- load polycore theme as default
current_theme = require('src/themes/dimensions')

local core = require('src/widgets/core')
local containers = require('src/widgets/containers')
local text = require('src/widgets/text')
local polycore = require('src/polycore')
local util = require('src/util')

local width = 1000
local height = 500

local LOREM_IPSUM = [[Lorem ipsum dolor sit amet, consectetur adipiscing elit,
sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit
esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat
cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est
laborum.]]

--- Called once on startup to initialize widgets.
-- @treturn core.Renderer
function polycore.setup()
    -- news ticker style text line
    local ticker = text.TextLine{align=CAIRO_TEXT_ALIGN_CENTER}
    local line_width = 80  -- arbitrary estiamte
    local lipsum = LOREM_IPSUM:gsub("\n", " ")
    lipsum = lipsum .. " " .. lipsum:sub(1, line_width)
    function ticker:update(update_count)
        local offset = update_count % #lipsum
        self:set_text(lipsum:sub(offset, offset + line_width))
        -- Always update
        return true
    end

    -- These test meshes but I also wanted to use them independently
    local status_font = {font_family="Sixteen-Mono", color=current_theme.header_color, font_size=30, border_width=1.2, border_color=current_theme.temperature_colors[2]}
    local status_font_sm = {font_family="Sixteen-Mono", color=current_theme.header_color, font_size=16, border_width=0.8, border_color=current_theme.temperature_colors[2]}

    local widgets = {
        -- heading
        containers.Frame(text.StaticText("Text Demo", {
                font_family="Ubuntu:Bold",
                font_size=20,
                color=core.default_graph_color,
            }), {
            margin={0, 0, 10},
            border_sides={"bottom"},
            border_width=1,
            border_color={1, 1, 1, .5},
        }),

        --core.Columns{
            containers.Rows{
                -- simple text
                text.StaticText("Hello World!", {}),
                core.Filler{height=10},
                
                text.StaticText(" 0 1 2 3 4 5 6 7 8 9 0 : ", status_font),
                text.StaticText(" AM PM ", status_font_sm),


                text.StaticText("الاثنين السبت", {font_family="Noto Sans Arabic", font_size=8, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("يوم السبت", {font_family="Noto Sans Arabic", font_size=10, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("الأربعاء السبت", {font_family="Noto Sans Arabic", font_size=12, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("يوم السبت", {font_family="Noto Sans Arabic", font_size=16, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("جمعة السبت", {font_family="Noto Sans Arabic", font_size=20, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("السبت", {font_family="Noto Sans Arabic", font_size=24, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("الأحد السبت", {font_family="Noto Sans Arabic", font_size=48, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),

                text.StaticText("الاثنين السبت", {font_family="Mashq", font_size=8, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("يوم السبت", {font_family="Mashq", font_size=10, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("الأربعاء السبت", {font_family="Mashq", font_size=12, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("يوم السبت", {font_family="Mashq", font_size=16, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("جمعة السبت", {font_family="Mashq", font_size=20, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("السبت", {font_family="Mashq", font_size=24, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("الأحد السبت", {font_family="Mashq", font_size=48, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),

                text.StaticText("الاثنين السبت", {font_family="Cortoba", font_size=8, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("يوم السبت", {font_family="Cortoba", font_size=10, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("الأربعاء السبت", {font_family="Cortoba", font_size=12, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("يوم السبت", {font_family="Cortoba", font_size=16, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("جمعة السبت", {font_family="Cortoba", font_size=20, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("السبت", {font_family="Cortoba", font_size=24, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                text.StaticText("الأحد السبت", {font_family="Cortoba", font_size=48, align=CAIRO_TEXT_ALIGN_LEFT, font_direction="RTL", font_script="HB_SCRIPT_ARABIC", font_language="ar"}),
                core.Filler{height=10},

                -- paragraph with newlines
                text.StaticText(LOREM_IPSUM, {
                    font_family="Ubuntu:Italic",
                    align=CAIRO_TEXT_ALIGN_CENTER,
                }),
            },
            core.Filler{width=10},
            text.StaticText("這是一些中文", {font_family="Source Han Sans TW", font_size=16,font_direction="TTB",font_script="HB_SCRIPT_HAN",font_language="ch"});
            core.Filler{width=10},
            core.Rows{
                -- simple text
                text.StaticText("Hello World!",{}),
                core.Filler{height=10},
                text.StaticText("How are you doing?", {align=CAIRO_TEXT_ALIGN_RIGHT}),


                core.Filler{height=10},

                -- paragraph with newlines
                text.StaticText(LOREM_IPSUM, {
                    font_family="Ubuntu:Italic",
                    align=CAIRO_TEXT_ALIGN_CENTER,
                }),
            },
        --},
        core.Filler{height=10},
        core.Frame(ticker, {
        border_sides={"top"},
        border_width=1,
        border_color={1, 1, 1, .5},}),
    }

    local root = core.Frame(core.Rows(widgets), {margin=10})
    return core.Renderer{root=root, width=width, height=height}
end


local conkyrc = conky or {}
local script_config = {
    lua_load = script_dir .. "text.lua",

    alignment = 'top_left',
    gap_x = 0,
    gap_y = 0,
    minimum_width = width,
    maximum_width = width,
    minimum_height = height,

    -- colors --
    own_window_colour = '131313',
    own_window_argb_visual = true,
    own_window_argb_value = 255,
    default_color = 'fafafa',
}

local core_config = require('src/config/core')

if os.getenv("DESKTOP") == "Enlightenment" then
    wm_config = require('src/config/enlightenment')
else
    wm_config = require('src/config/awesome')
end

local tmp_config = util.merge_table(core_config, wm_config)
local config = util.merge_table(tmp_config, script_config)

conkyrc.config = config

conkyrc.text = ""
