--- Conky entry point script

-- Conky does not add our config directory to lua's PATH, so we do it manually
local script_dir = debug.getinfo(1, 'S').source:match("^@(.*/)") or "./"
package.path = script_dir .. "?.lua;" .. package.path

-- load polycore theme as default
current_theme = require('src/themes/polycore')

local conkyrc = require('conkyrc')
local polycore = require('src/polycore')
local data = require('src/data')
local core  = require('src/widgets/core')
local cpu   = require('src/widgets/cpu')
local drive = require('src/widgets/drive')
local gpu   = require('src/widgets/gpu')
local images = require('src/widgets/images')
local mem   = require('src/widgets/memory')
local net   = require('src/widgets/network')
local text  = require('src/widgets/text')

local Frame, Filler, Rows, Columns, Float, Stack = core.Frame, core.Filler,
                                          core.Rows, core.Columns, core.Float, core.Stack
local Cpu, CpuFrequencies, CpuTop = cpu.Cpu, cpu.CpuFrequencies, cpu.CpuTop
local Drive = drive.Drive
local Gpu, GpuTop = gpu.Gpu, gpu.GpuTop
local StaticImage = images.StaticImage
local MemoryGrid, MemTop = mem.MemoryGrid, mem.MemTop
local Network = net.Network
local ConkyText, StaticText, TextLine = text.ConkyText, text.StaticText, text.TextLine


-- Draw debug information
DEBUG = false


--- Called once on startup to initialize widgets.
-- @treturn core.Renderer
function polycore.setup()
    -- Write fan speeds. This requires lm_sensors to be installed.
    -- Run `sensonrs` to see if any fans are reported. If not, remove
    -- this section and the corresponding line below.
    local fan_rpm_text = text.TextLine{align=CAIRO_TEXT_ALIGN_CENTER, color=current_theme.secondary_text_color}
    fan_rpm_text.update = function(self)
        local fans = data.fan_rpm()
        self:set_text(table.concat{fans[1], " rpm   ·   ", fans[2], " rpm"})
    end

    -- Write individual CPU core temperatures as text.
    -- This also relies on lm_sensors.
    local cpu_temps_text = text.TextLine{align=CAIRO_TEXT_ALIGN_CENTER, color=current_theme.secondary_text_color}
    cpu_temps_text.update = function(self)
        local cpu_temps = data.cpu_temperatures()
        self:set_text(table.concat(cpu_temps, " · ") .. " °C")
    end

    -- Write individual CPU core temperatures as text.
    -- This also relies on lm_sensors.
    local gpu_power_text = text.TextLine{align="right", font_size=10.1}
    gpu_power_text.update = function(self)
        local fans = data.fan_rpm()
        local gpu_power_draw = string.format("%.0f", data.gpu_power_draw())
        if (fans[5]) then
            self:set_text(table.concat{gpu_power_draw, " W       ", fans[5], " rpm"})
        else
            self:set_text(table.concat{gpu_power_draw, " W       "})
        end
    end

    local title_font = {color=current_theme.highlight_color,font_family=current_theme.default_bold_font_family, font_size=20, align=CAIRO_TEXT_ALIGN_CENTER}
    local centered_font = {color=current_theme.secondary_text_color,font_family=current_theme.default_font_family, font_size=current_theme.default_font_size, align=CAIRO_TEXT_ALIGN_CENTER}
    local header_font = {color=current_theme.header_color,font_family=current_theme.default_font_family, font_size=current_theme.header_font_size}
    local status_font = {color=current_theme.secondary_text_color,font_family=current_theme.default_font_family, font_size=current_theme.default_font_size, align=CAIRO_TEXT_ALIGN_RIGHT}

    local block_space = 12

    local widgets = {
        StaticText("pCore2", title_font),
        Filler{height=10},
        ConkyText("${time %d.%m.%Y}", centered_font),
        ConkyText("${time %H:%M}", centered_font),
        Filler{height=3},
        fan_rpm_text,  -- see above
        cpu_temps_text,  -- see above
        Filler{height=8},

        -- Adjust the CPU core count to your system.
        -- Requires lm_sensors for CPU temperatures.
        Cpu{cores=8, inner_radius=28, gap=5, outer_radius=57},
        Filler{height=7},
        CpuFrequencies{cores=8, min_freq=0.75, max_freq=4.3},
        Filler{height=10},
        Columns{StaticText("[   top   ]", header_font), ConkyText("${cpu 0}%", status_font)},
        CpuTop({}),
        Filler{height=block_space},

        -- See also widget.MemoryBar
        Columns{StaticText("[   mem   ]", header_font), ConkyText("${memperc}%", status_font)},
        MemoryGrid{rows=5},
        MemTop({}),
        Filler{height=block_space},

        -- Requires `nvidia-smi` to be installed. Does not work for AMD GPUs.
        Columns{StaticText("[   gpu   ]", header_font), 
                ConkyText("${nvidia gpufreq} MHz", status_font)},
        Columns{Filler{width=8}, gpu_power_text, ConkyText("${nvidia temp}°C", status_font)}, -- see above
        Filler{height=2},
        Gpu(),
        Filler{height=1},
        GpuTop{lines=5, color=current_theme.secondary_text_color},
        Filler{height=block_space},

        StaticText("[   net   ]", header_font),
        -- Adjust the interface name for your system. Run `ifconfig` to find
        -- out yours. Common names are "eth0" and "wlan0".
        Network{interface="enp0s13f0u1u4u4", downspeed=5 * 1024, upspeed=1024,
                       graph_height=22},
        Filler{height=block_space},

        -- Mount paths. Devices that aren't mounted will not be rendered until
        -- they appear. That way external drives can be displayed automatically.
        drive.Drive("/", {device="nvme0n1p1", physical_device="nvme0n1"}),
        drive.Drive("/home", {device="nvme0n1p2", physical_device="nvme0n1"}),
        core.Filler{height=600},
        StaticImage("/home/simon/src/devel/conky-bubbles/assets/pcore2/9blocks.png",{})
    }
    local root = core.Frame(core.Rows(widgets), {
        padding={20, 20, 20, 20},
        border_color={0.8, 1, 1, 0.05},
        border_width = 1,
        border_sides = {"right"},
    })
    --local root = core.Rows(widgets)
    return core.Renderer{root=root,
                           width=conkyrc.config.minimum_width,
                           height=conkyrc.config.minimum_height}
end
