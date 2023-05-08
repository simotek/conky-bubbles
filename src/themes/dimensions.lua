--- A collection of Widget classes
-- @module dimensions_theme
-- @alias dt

pcall(function() require('cairo') end)

-- Specified here so it can be used in multiple places
local default_graph_color = "3498d8"

theme = {
    --- Font used by widgets if no other is specified.
    -- @string default_font_family
    default_font_family = "Ubuntu",

    --- Font size used by widgets if no other is specified.
    -- @int default_font_size
    default_font_size = 10,

    --- Text color used by widgets if no other is specified.
    -- @string default_text_color a color hex string
    default_text_color = "fafafa",  -- ~fafafa

    --- A secondary color text color you can use in your themes
    -- currently it is not used by any of the widgets.
    -- @string secondary_text_color a color hex string
    secondary_text_color = "b9b9b7",  -- ~b9b9b7

    --- Color used to draw some widgets if no other is specified.
    -- @string default_graph_color a color hex string
    default_graph_color = default_graph_color,

    temperature_colors = {
        default_graph_color,
        "025286",
        "484b9a",
        "8e44ad",
        "8d3733",
        "8d2f25",
    }
}

return theme
