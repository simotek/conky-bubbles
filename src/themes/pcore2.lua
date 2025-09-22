--- The default polycore theme
-- @module polycore_theme
-- @alias pt

pcall(function() require('cairo') end)

-- Specified here so it can be used in multiple places
local highlight_color = "66ffff"

local theme = {
    --- Font used by widgets if no other is specified.
    -- @string default_font_family
    default_font_family = "Play",

    --- Bold Font used by widgets if no other is specified.
    -- @string default_bold_font_family
    default_bold_font_family = "Play:Bold",

    --- Font size used by widgets if no other is specified.
    -- @int default_font_size
    default_font_size = 12,

    --- Font size used by widgets if no other is specified.
    -- @int default_font_size
    header_font_size = 14,

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

    temperature_colors = {
        highlight_color,
        "7fffcc",
        "b2e599",
        "ffe566",
        "ff9933",
        "ff3333",
    },

    --- Color for Green LED's.
    -- @string green_led_color a color hex string
    green_led_color = "b2e599",

    --- Color for Red LED's.
    -- @string red_led_color a color hex string
    red_led_color = "ff9933"
}

return theme
