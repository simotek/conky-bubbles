--- A remake of the polycore theme
-- @module pcore2_theme
-- @alias pt

pcall(function() require('cairo') end)

-- Specified here so it can be used in multiple places
local highlight_color = "66ffff"

-- 6 Colors that scale from use at coldest temps to Hottest.
local temperature_colors = {
        highlight_color,
        "7fffcc",
        "b2e599",
        "ffe566",
        "ff9933",
        "ff3333",
    }
-- This is different in other themes
local header_color = highlight_color

local header_font_size = 11

local default_text_color = "b9b9b7"

local theme = {
    --- Font used by widgets if no other is specified.
    -- @string default_font_family
    default_font_family = "Ubuntu",

    --- Bold Font used by widgets if no other is specified.
    -- @string default_bold_font_family
    default_bold_font_family = "Ubuntu:Bold",

    --- Font size used by widgets if no other is specified.
    -- @int default_font_size
    default_font_size = 10,

    --- Font size used by widgets if no other is specified.
    -- @int default_font_size
    header_font_size = header_font_size,

    default_font_direction = "LTR", 
    default_font_script = "Zyyy", 
    default_font_language = "en",

    --- Text color used by widgets if no other is specified.
    -- @string default_text_color a color hex string
    default_text_color = "b9b9b7",  -- ~b9b9b7

    --- A secondary color text color you can use in your themes
    -- currently it is not used by any of the widgets.
    -- @string secondary_text_color a color hex string
    secondary_text_color = "fafafa",  -- ~fafafa

    --- Color used to draw some widgets if no other is specified.
    -- @string default_graph_color a color hex string
    highlight_color = highlight_color,

    --- Color used for drawing titles / headers (not used by widgets)
    -- @string header_color a color hex string
    header_color = "55AAAA",

    --- Color used to draw graph widgets if no other is specified.
    -- @string graph_color a color hex string
    graph_color = highlight_color,

    --- Color used to draw some widgets if no other is specified.
    -- @string background_color a color hex string
    background_color = "666666",

    --- A table of colors that are used for text in the "top" wigdets
    -- ie CpuTop, MemTop, GpuTop
    -- a table of 5 strings containing hex colors without the leading #
    -- This theme just uses the default color
    top_colors = {
        default_text_color,
        default_text_color,
        default_text_color,
        default_text_color,
        default_text_color,
        default_text_color,
    },

    --- A table of colors that are used for temperature graphs
    -- in the CPU Widgets
    -- a table temperature_colors strings containing hex colors without the leading #
    temperature_colors = temperature_colors,

    --- Font used in block widget for header
    -- A table of args that can be passed to Static or Conky text
    header_font = {color=header_color,font_family="Ubuntu", font_size=header_font_size, border_width=0.8, border_color=temperature_colors[2]},
    
    --- Font used in block widget for status text
    -- A table of args that can be passed to Static or Conky text
    status_font = {color=temperature_colors[3],font_family="Ubuntu-Mono", font_size=header_font_size, border_width=0.3, border_color=temperature_colors[2]},


    --- Color for Green LED's.
    -- @string green_led_color a color hex string
    green_led_color = "b2e599",

    --- Color for Red LED's.
    -- @string red_led_color a color hex string
    red_led_color = "ff9933"
}

return theme
