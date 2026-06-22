--- Conky config script

-- Conky does not add our config directory to lua's PATH, so we do it manually
local script_dir = debug.getinfo(1, 'S').source:match("^@(.*/)") or "./"
package.path = script_dir .. "../?.lua;" .. package.path
local rc_path = debug.getinfo(1, 'S').source:match("[^/]*.lua$")

-- load polycore theme as default
current_theme = require('src/themes/pcore2')

local util = require('src/util')
local data = require('src/data')
local bubbles = require('src/bubbles')
local core  = require('src/widgets/core')
local containers  = require('src/widgets/containers')
local cpu   = require('src/widgets/cpu')
local cl = require('src/config_loader')

local Frame, Filler, Rows, Columns, Float, Stack, Block = containers.Frame, containers.Filler,
                                          containers.Rows, containers.Columns, containers.Float, containers.Stack, containers.Block


local width = 1000
local height = 640

--- Called once on startup to initialize widgets.
-- @treturn widget.Renderer
function bubbles.setup()

    -- dirty hack to pretend I have more cores than I actually do
    local real_cores = 6
    for _, data_fn in ipairs{"cpu_frequencies", "cpu_percentages", "cpu_temperatures"} do
        local fn = data[data_fn]
        data[data_fn] = function()
            local results = fn(real_cores)
            local num_results = #results
            for i = 1, 64 do
                if results[i] == nil then
                    local base_val = num_results > 0 and results[(i - 1) % num_results + 1] or 0
                    results[i] = base_val * (math.random() * 0.5 + 0.75)
                end
            end
            util.shuffle(results)
            return results
        end
    end

    local root = Frame(Rows{
        Columns{
            Rows{
                cpu.Cpu{cores=6, outer_radius=52, inner_radius=26, gap=5},
                Filler{height=20},
                cpu.Cpu{cores=10, outer_radius=52, inner_radius=30, gap=3},
            },
            Rows{
                cpu.Cpu{cores=8, outer_radius=52, inner_radius=24, gap=7},
                Filler{height=20},
                cpu.Cpu{cores=12, outer_radius=52, inner_radius=36, gap=5},
            },
            Filler{width=20},
            cpu.Cpu{cores=6, gap=7, outer_radius=100, rounded=true},
        },
        Filler{},
        Columns{
            Rows{
                cpu.CpuRound{cores=6, outer_radius=52, inner_radius=26},
                Filler{height=20},
                cpu.CpuRound{cores=16, outer_radius=52, inner_radius=30},
            },
            Rows{
                cpu.CpuRound{cores=6, outer_radius=52, inner_radius=24, grid=5},
                Filler{height=20},
                cpu.CpuRound{cores=32, outer_radius=52, inner_radius=36, grid=4},
            },
            Filler{width=20},
            cpu.CpuRound{cores=64, outer_radius=100, grid=5},
            Rows{
                cpu.CpuCombo{cores=6, outer_radius=52, mid_radius=36, inner_radius=26},
                core.Filler{height=20},
                cpu.CpuCombo{cores=16, outer_radius=52, mid_radius=40, inner_radius=30, grid=5},
            },
        },

    }, {padding=20})
    return core.Renderer{root=root, width=width, height=height}
end


local conkyrc = conky or {}
script_config = {
    lua_load = script_dir .. rc_path,

    alignment = 'middle_middle',
    gap_x = 0,
    gap_y = 0,
    minimum_width = width,
    maximum_width = width,
    minimum_height = height,

    -- colors --
    own_window_colour = 'E6131313',
    default_color = 'fafafa',
}

conkyrc.config = cl.load_config(script_config)

conkyrc.text = ""
