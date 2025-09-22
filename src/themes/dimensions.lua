--- The Dimensions Theme
-- @module dimensions_theme
-- @alias dt

pcall(function() require('cairo') end)
local ch = require('src/cairo_helpers')

-- Specified here so it can be used in multiple places
local highlight_color = "3498d8"
local temperature_colors = {
        highlight_color,
        "025286",
        "484b9a",
        "8e44ad",
        "8d3733",
        "8d2f25",
    }
-- This is different in other themes
local header_color = highlight_color

local header_font_size = 16

local theme = {
    --- Font used by widgets if no other is specified.
    -- @string default_font_family
    default_font_family = "SUSE",

    --- Bold Font used by widgets if no other is specified.
    -- @string default_bold_font_family
    default_bold_font_family = "SUSE:Bold",

    --- Font size used by widgets if no other is specified.
    -- @int default_font_size
    default_font_size = 12,

    --- Font size used by widgets if no other is specified.
    -- @int default_font_size
    header_font_size = header_font_size,

    default_font_direction = "LTR", 
    default_font_script = "Zyyy", 
    default_font_language = "en",
    --- Text color used by widgets if no other is specified.
    -- @string default_text_color a color hex string
    default_text_color = "fafafa",  -- ~fafafa

    --- A secondary color text color you can use in your themes
    -- currently it is not used by any of the widgets.
    -- @string secondary_text_color a color hex string
    secondary_text_color = "b9b9b7",  -- ~b9b9b7

    --- Color used to draw some widgets if no other is specified.
    -- @string highlight_color a color hex string
    highlight_color = highlight_color,

    --- Color used for drawing titles / headers (not used by widgets)
    -- @string header_color a color hex string
    header_color = highlight_color,

    --- Color used to draw graph widgets if no other is specified.
    -- @string graph_color a color hex string
    graph_color = highlight_color,

    --- Color used to draw some widgets if no other is specified.
    -- @string background_color a color hex string
    background_color = "666666",

    --- A table of colors that are used for text in the "top" wigdets
    -- ie CpuTop, MemTop, GpuTop
    -- @table strings containing hex colors without the leading #
    top_colors = {
        highlight_color,
        "dddddd",
        "aaaaaa",
        "888888",
        "666666",
    },

    --- A table of colors that are used for temperature graphs
    -- in the CPU Widgets
    -- @table strings containing hex colors without the leading #
    temperature_colors = temperature_colors,

    --- Font used in block widget for header
    -- @table A table of args that can be passed to Static or Conky text
    header_font = {color=header_color,font_family="Sixteen", font_size=header_font_size, border_width=0.8, border_color=temperature_colors[2]},
    
    --- Font used in block widget for status text
    -- @table A table of args that can be passed to Static or Conky text
    status_font = {color=temperature_colors[3],font_family="Sixteen-Mono", font_size=header_font_size, border_width=0.3, border_color=temperature_colors[2]},


    --- Color for Green LED's.
    -- @string green_led_color a color hex string
    green_led_color = "489a4b",

    --- Color for Red LED's.
    -- @string red_led_color a color hex string
    red_led_color = "8d2f25"
}

return theme
