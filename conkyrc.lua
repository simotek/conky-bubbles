--- Conky config script

local conkyrc = conky or {}

local script_dir = debug.getinfo(1, 'S').source:match("^@(.*/)") or "./"

local util = require('src/util')

script_config = {
    lua_load = script_dir .. "layout.lua",

    -- positioning --
    alignment = 'top_left',
    gap_x = 0,
    gap_y = 28,
    minimum_width = 160,
    maximum_width = 160,
    minimum_height = 1080 - 28,
    xinerama_head = 3,

    -- font --
    font = 'Ubuntu:pixelsize=10',
    draw_shades = true,
    default_shade_color = 'black',
    --use_xft = true,  -- Use Xft (anti-aliased font and stuff)

    -- colors --
    own_window_colour = '131313',
    own_window_argb_visual = true,
    own_window_argb_value = 180,
    default_color = 'fafafa',
    color0 = '337777',  -- titles
    color1 = 'b9b9b7',  -- secondary text color
    color2 = 'bb5544',  -- high temperature warning color

    -----------------
    --- templates ---
    -----------------

    -- title: title
    template1 = [[
${template9}${offset 1}${font Ubuntu:pixelsize=11:bold}${color0}[ \1 ]$color$font]],

    -- top (cpu): number
    template2 = [[
${template9}${color1}${top name \1}${template8}${top cpu \1} %$color]],

    -- top (mem): number
    template3 = [[
${template9}${color1}${top_mem name \1}${template8}${top_mem mem_res \1}$color]],

    -- drives: name dir --
    template5 = [[
${if_mounted \2}
${template9}${offset 1}${font Ubuntu:pixelsize=11:bold}${color0}· \1 ·
${voffset 8}#
${template9}${color1}${font Ubuntu:pixelsize=10}${fs_used \2}  /  ${fs_size \2}#
${if_match ${fs_used_perc \2}>=85}${color2}$else$color$endif#
${template8}${fs_used_perc \2}%$font$color
$endif]],

    -- distance middle | right | left
    template7 = '${alignc}',
    template8 = '${alignr 10}',
    template9 = '${goto 10}',
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
### drives ###
${template5 root /}#
${template5 home /home}#

#
${image 9blocks.png -p 60,990 -s 16x16}#
]]

return conkyrc
