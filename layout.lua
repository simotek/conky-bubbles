--- Conky entry point script

-- Conky does not add our config directory to lua's PATH, so we do it manually
local script_dir = debug.getinfo(1, 'S').source:match("^@(.*/)") or "./"
package.path = script_dir .. "?.lua;" .. package.path

local conkyrc = require('conkyrc')
local polycore = require('src/polycore')
local data = require('src/data')
local widget = require('src/widget')

-- Draw debug information
DEBUG = false


--- Called once on startup to initialize widgets.
-- @treturn widget.Renderer
function polycore.setup()

    local main_title_text_color = {.26, .86, .86, 1} -- ~4dd 
    local secondary_text_color = {.72, .72, .71, 1}  -- ~b9b9b7
    
    -- Title Text
    local title_first = widget.StaticText("Poly", {align="right", font_family="TeXGyreChorus", font_weight="bold", font_size=28})
    local title_second = widget.StaticText("core", {align="left", font_family="TeXGyreChorus", font_weight="bold", font_size=28, color=main_title_text_color})
    local title_text = widget.Columns{widget.Filler{width=10}, title_first, title_second, widget.Filler{width=10}}

    -- Write fan speeds. This requires lm_sensors to be installed.
    -- Run `sensonrs` to see if any fans are reported. If not, remove
    -- this section and the corresponding line below.
    local fan_rpm_text = widget.TextLine{align="center", color=secondary_text_color}
    fan_rpm_text.update = function(self)
        local fans = data.fan_rpm()
        self:set_text(table.concat{fans[1], " rpm   ·   ", fans[2], " rpm"})
    end

    -- Write individual CPU core temperatures as text.
    -- This also relies on lm_sensors.
    local cpu_temps_text = widget.TextLine{align="center", color=secondary_text_color}
    cpu_temps_text.update = function(self)
        local cpu_temps = data.cpu_temperatures()
        self:set_text(table.concat(cpu_temps, " · ") .. " °C")
    end

    local widgets = {
        title_text,  -- see above
        widget.Filler{height=3},
        fan_rpm_text,  -- see above
        cpu_temps_text,  -- see above
        widget.Filler{height=3},

        -- Adjust the CPU core count to your system.
        -- Requires lm_sensors for CPU temperatures.
        widget.Cpu{cores=6, inner_radius=28, gap=5, outer_radius=57},
        widget.Filler{height=7},
        widget.CpuFrequencies{cores=6, min_freq=0.75, max_freq=4.3},
        widget.Filler{height=136},

        -- See also widget.MemoryBar
        widget.MemoryGrid{rows=5},
        widget.Filler{height=82},

        -- Requires `nvidia-smi` to be installed. Does not work for AMD GPUs.
        --widget.Gpu(),
        widget.Filler{height=1},
        --widget.GpuTop{lines=5, color=secondary_text_color},
        widget.Filler{height=66},

        -- Adjust the interface name for your system. Run `ifconfig` to find
        -- out yours. Common names are "eth0" and "wlan0".
        widget.Network{interface="eth0", downspeed=5 * 1024, upspeed=1024,
                       graph_height=22},
        widget.Filler{height=34},

        -- Mount paths. Devices that aren't mounted will not be rendered until
        -- they appear. That way external drives can be displayed automatically.
        --widget.Drive("/"),
        --widget.Drive("/home"),
        --widget.Drive("/mnt/blackstor"),
        --widget.Drive("/mnt/bluestor"),
        --widget.Drive("/mnt/cryptstor"),
        widget.Filler(),
    }
    local root = widget.Frame(widget.Group(widgets), {
        padding={108, 9, 10, 10},
        border_color={0.8, 1, 1, 0.05},
        border_width = 1,
        border_sides = {"left"},
    })
    return widget.Renderer{root=root,
                           -- width=conkyrc.config.minimum_width,
                           width=200,
                           height=conkyrc.config.minimum_height}
end
