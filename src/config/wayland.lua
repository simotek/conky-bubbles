--- conky config options for all wayland desktops
-- @module config_wayland
-- @alias cc

pcall(function() require('cairo') end)

local config = {
    -- wayland --
    out_to_x = false,
    out_to_wayland = true,
}

return config
