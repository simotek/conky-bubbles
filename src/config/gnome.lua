--- conky config options for gnome
-- @module config_gnome
-- @alias cc

pcall(function() require('cairo') end)

local config = {
    -- awesome wm --
    own_window = true,
    own_window_class = 'conky',
    own_window_type = 'desktop',
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',
    double_buffer = true
}

return config