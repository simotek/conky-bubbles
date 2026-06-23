--- Data gathering facilities for conky widgets
-- @module data

local lfs = require('lfs')

local util = require('src/util')
local has_cjson, cjson = pcall(require, 'cjson')

-- lua 5.1 to 5.3 compatibility
local unpack = unpack or table.unpack  -- luacheck: read_globals unpack table

local data = {}

local read_cmd = util.memoize(1, function(cmd)
    local pipe = io.popen(cmd)
    local result = pipe:read("*a")
    local success, exit_or_signal, n = pipe:close()
    if not success then
        print("Command '" .. cmd .. "' failed.")
    end
    return result
end)

local read_number_from_file = util.memoize(1, function(path)
    local file = io.open(path, "r")
    if not file then
        print("Failed to open file '" .. path .. "'.")
        return -1
    end
    local result = file:read("n")
    file:close()
    return result
end)

local unit_map = {
    B = 1,
    kB = 1000, KB = 1000, MB = 1000 ^ 2, GB = 1000 ^ 3, TB = 1000 ^ 4,
    kiB = 1024, KiB = 1024, MiB = 1024 ^ 2, GiB = 1024 ^ 3, TiB = 1024 ^ 4,
}

--- Convert memory value from one unit to another.
-- @string from like "B", "MiB", "kB", ...
-- @tparam string|nil to like "B", "MiB", "kB", ...
--                       For nil, no conversion happens.
-- @number value amount of memory in `from` unit
local function convert_unit(from, to, value)
    if to and from ~= to then
        return value * unit_map[from] / unit_map[to]
    end
    return value
end

-- Gather parameters for expensive calls and run them in bulk on the next update.
local EagerLoader = util.class()


--- Create an EagerLoader instance.
-- Pass a function that takes a list of keys and returns an iterator of values.
-- @tparam function fetch_data
function EagerLoader:init(fetch_data)
    self.fetch_data = fetch_data
    self._vars = {}  -- maps vars to max age
    self._results = {}  -- maps vars to results
end

--- Run a bulk conky_parse with collected strings from previous updates.
-- Called at the begin of each update to greatly improve performance.
-- @function EagerLoader:load
function EagerLoader:load()
    -- clean up results that were not requested in the last update
    for var, _ in pairs(self._results) do
        if not self._vars[var] then
            self._results[var] = nil
        end
    end

    local vars = {}

    -- age remembered variables, queue outdated ones for evaluation
    local i = 1
    for var, remember in pairs(self._vars) do
        remember = remember > 1 and remember - 1 or nil
        self._vars[var] = remember
        if not remember then
            self._results[var] = nil
            vars[i] = var
            i = i + 1
        end
    end
    if i == 1 then return end

    -- parse collected variables
    i = 1
    for result in self.fetch_data(vars) do
        self._results[vars[i]] = result
        i = i + 1
    end
end

--- Retrieve a conky_parse result.
-- @usage
-- data.eager_loader:get("$update")
-- data.eager_loader:get("${cpu cpu%s}", 2)  -- usage of second CPU core
-- data.eager_loader:get(5, "${fs_used_perc %s}", "/home")  -- cached for 5 updates
-- @function EagerLoader:get
-- @int[opt=1] remember
-- @string var string to be evaluated by `conky_parse`
-- @param[opt] ... Additional arguments passed to `var:format(...)`
-- @treturn string result of `conky_parse(var)`
function EagerLoader:get(remember, var, ...)
    if type(remember) == "string" then  -- skipped first argument
        var = var and remember:format(var, ...) or remember
        remember = 1
    elseif ... then
        var = var:format(...)
    end

    -- queue this variable for future updates
    if not self._vars[var] then
        self._vars[var] = remember or 1
    end

    -- retrieve the result
    if not self._results[var] then
        self._results[var] = self.fetch_data({var})()
    end
    return self._results[var]
end

data.gpu=nil
-- local ConkyLoader = util.class(EagerLoader)
local conky_loader = EagerLoader(function(vars)
    local output = conky_parse("<|" .. table.concat(vars, "|><|") .. "|>")
    return output:gmatch("<|(.-)|>")
end)
data.conky_loader = conky_loader


local nvidia_loader = EagerLoader(function(vars)
    local output = read_cmd("nvidia-smi --format=csv,noheader,nounits --query-gpu=" .. table.concat(vars, ","))
    return (", " .. output):gmatch(", ([^,]+)")
end)
data.nvidia_loader = nvidia_loader

--- Loader for running commands that return JSON and caching/parsing the results.
-- @type JsonEagerLoader
local JsonEagerLoader = util.class()
data.JsonEagerLoader = JsonEagerLoader

--- Create a JsonEagerLoader instance.
-- @string cmd The command to execute that returns a JSON string.
function JsonEagerLoader:init(cmd)
    self._cmd = cmd
    self._loaded = false
    self._parsed_data = nil
end

--- Reset the loader state.
-- Call this at the start of each update cycle to allow lazy-loading.
function JsonEagerLoader:load()
    self._loaded = false
    self._parsed_data = nil
end

--- Retrieve parsed JSON data using a string path.
-- @param parser A dot-separated string path (e.g., "outputs.1.size.width")
-- @return The requested value, or nil if not found or parsing failed.
function JsonEagerLoader:get(parser)
    if not self._loaded then
        self._loaded = true
        if not has_cjson then
            print("JsonEagerLoader: cjson is not installed, cannot parse command output.")
            return nil
        end

        local raw_output = read_cmd(self._cmd)
        if raw_output and raw_output ~= "" then
            local parsed = cjson.decode(raw_output)
            self._parsed_data = parsed
        end
    end

    if not self._parsed_data or type(parser) ~= "string" then
        return nil
    end

    local current = self._parsed_data
    for segment in string.gmatch(parser, "[^%.]+") do
        if type(current) ~= "table" then return nil end
        local num = tonumber(segment)
        current = current[num or segment]
    end
    return current
end

local amd_stats_loader = JsonEagerLoader("amdgpu_top -d -gm --json")
data.amd_stats_loader = amd_stats_loader

local amd_process_loader = JsonEagerLoader("amdgpu_top -d -p --json")
data.amd_process_loader = amd_process_loader

local cached_core_count = nil

--- Get the hardware CPU core count
-- @treturn number
function data.cpu_cores()
    if not cached_core_count then
        cached_core_count = tonumber(read_cmd("nproc")) or 1
    end
    return cached_core_count
end

--- Get the current usage percentages of individual CPU cores
-- @int cores number of CPU cores
-- @treturn {number,...}
function data.cpu_percentages(cores)
    local actual_cores = data.cpu_cores()
    local limit = math.min(cores, actual_cores)
    local conky_string = "${cpu cpu1}"
    for i = 2, limit do
        conky_string = conky_string .. "|${cpu cpu" .. i .. "}"
    end
    local results = util.map(tonumber, conky_loader:get(conky_string):gmatch("%d+"))
    for i = 1, cores do
        results[i] = results[i] or 0
    end
    return results
end

--- Get the current frequencies at which individual CPU cores are running
-- @int cores number of CPU cores
-- @treturn {number,...}
function data.cpu_frequencies(cores)
    local actual_cores = data.cpu_cores()
    local limit = math.min(cores, actual_cores)
    local conky_string = "${freq_g 1}"
    for i = 2, limit do
        conky_string = conky_string .. "|${freq_g " .. i .. "}"
    end
    local results = util.map(tonumber, conky_loader:get(conky_string):gmatch("%d+[,.]?%d*"))
    for i = 1, cores do
        results[i] = results[i] or 0
    end
    return results
end

local cached_cpu_freqs = false
local cached_cpu_min_freq = 0
local cached_cpu_max_freq = 0

local function fetch_cpu_freq_limits()
    if not cached_cpu_freqs then
        local output = read_cmd("lscpu")
        local max_freq = output:match("CPU max MHz:%s+(%d+%.?%d*)")
        local min_freq = output:match("CPU min MHz:%s+(%d+%.?%d*)")
        cached_cpu_max_freq = tonumber(max_freq)/1000 or 0
        cached_cpu_min_freq = tonumber(min_freq)/1000 or 0
        cached_cpu_freqs = true
    end
end

--- Get the minimum CPU frequency in MHz
-- @treturn number
function data.cpu_min_freq()
    fetch_cpu_freq_limits()
    return cached_cpu_min_freq
end

--- Get the maximum CPU frequency in MHz
-- @treturn number
function data.cpu_max_freq()
    fetch_cpu_freq_limits()
    return cached_cpu_max_freq
end

--- Get the current CPU core temperatures
-- relies on lm_sensors to be installed
-- @treturn {number,...}
function data.cpu_temperatures()
    local cores = util.map(tonumber, read_cmd("sensors"):gmatch("Core %d: +%+(%d%d)"))
    if #cores ~= 0 then
        return cores
    end
    -- CPU doesn't return per core info just return single CPU Temp
    return util.map(tonumber, read_cmd("sensors"):gmatch("CPU: +[%+%-]?(%d+%.?%d*)"))
end




--- Get the current speed of fans in the system
-- relies on lm_sensors to be installed
-- @treturn {number,...}
function data.fan_rpm()
    return util.map(tonumber, read_cmd("sensors"):gmatch("fan%d: +(%d+) RPM"))
end

--- Get current memory usage info
-- @tparam ?string unit like "B", "MiB", "kB", ...
-- @treturn number,number,number,number usage, easyfree, free, total
function data.memory(unit)
    local conky_output = conky_loader:get("$mem|$memeasyfree|$memfree|$memmax")
    local results = {}
    for value, parsed_unit in conky_output:gmatch("(%d+%p?%d*) ?(%w+)") do
        table.insert(results, convert_unit(parsed_unit, unit, tonumber(value)))
    end
    return unpack(results)
end

--- Get current GPU usage in percent.
-- Relies on nvidia-smi to be installed.
-- @treturn number
function data.gpu_percentage()
    if data.gpu == "nvidia" then
        return tonumber(nvidia_loader:get("utilization.gpu")) or 0
    elseif data.gpu == "amd" then
        return tonumber(amd_stats_loader:get("1.gpu_activity.GFX.value")) or 0
    else
        return 0
    end
end

--- Get current GPU frequency.
-- @treturn number in MHz
function data.gpu_frequency()
    if data.gpu == "nvidia" then
        return tonumber(nvidia_loader:get("clocks.current.graphics")) or 0
    elseif data.gpu == "amd" then
        return tonumber(amd_stats_loader:get("1.Sensors.GFX_SCLK.value")) or 0
    else
        return 0
    end
end

--- Get current GPU temperature.
-- Relies on nvidia-smi to be installed.
-- @treturn number temperature in °C
function data.gpu_temperature()
    if data.gpu == "nvidia" then
        return tonumber(nvidia_loader:get("temperature.gpu")) or 0
    elseif data.gpu == "amd" then
        local temp = tonumber(amd_stats_loader:get("1.gpu_metrics.temperature_gfx"))
        return temp and (temp / 100) or 0
    else
        return 0
    end
end

--- Get current VRAM usage.
-- Relies on nvidia-smi to be installed.
-- @treturn number,number used, total in MiB
function data.gpu_memory()
    if data.gpu == "nvidia" then
        return tonumber(nvidia_loader:get("memory.used")) or 0,
               tonumber(nvidia_loader:get("memory.total")) or 0
    elseif data.gpu == "amd" then
        return tonumber(amd_stats_loader:get("1.VRAM.Total VRAM Usage.value")) or 0,
               tonumber(amd_stats_loader:get("1.VRAM.Total VRAM.value")) or 0
    else
        return 0,0
    end
end

--- Get current GPU power draw.
-- Relies on nvidia-smi to be installed.
-- @treturn number power draw in W
function data.gpu_power_draw()
    if data.gpu == "nvidia" then
        return tonumber(nvidia_loader:get("power.draw")) or 0
    elseif data.gpu == "amd" then
        local power = tonumber(amd_stats_loader:get("1.gpu_metrics.average_socket_power"))
        return power and (power / 1000) or 0
    else
        return 0
    end
end

--- Get current GPU power draw.
-- Relies on nvidia-smi to be installed.
-- @treturn number power draw in W
function data.gpu_power_limit()
    if data.gpu == "nvidia" then
        return tonumber(nvidia_loader:get("power.limit")) or 0
    else
        return 0
    end
end

--- Get list of GPU processes with individual VRAM usage in MiB.
-- Relies on nvidia-smi to be installed.
-- @treturn {{string,number},...} list of {name, mem} value pairs.
function data.gpu_top()
    if data.gpu == "nvidia" then
        local output = read_cmd("nvidia-smi -q -d PIDS")
        local processes = {}
        for name, mem in output:gmatch("Name%s+: ([^\n]*)\n%s+Used GPU Memory%s+: (%d+)") do
            name = name:match(".*[/\\](.+)") or name
            processes[#processes + 1] = {name, tonumber(mem)}
        end
        table.sort(processes, function(proc1, proc2) return proc1[2] > proc2[2] end)
        return processes
    elseif data.gpu == "amd" then
        local processes = {}
        local raw_processes = amd_process_loader:get("devices.1.fdinfo") or amd_process_loader:get("devices.1.Fdinfo")
        
        if type(raw_processes) == "table" then
            for k, proc in pairs(raw_processes) do
                if type(proc) == "table" then
                    local name = proc.name or proc.comm or "unknown"
                    name = name:match(".*[/\\](.+)") or name
                    local raw_vram = 0
                    local usage1 = proc.usage or proc.Usage
                    if type(usage1) == "table" then
                        local usage2 = usage1.usage or usage1.Usage or usage1
                        local vram_table = usage2.VRAM or usage2.vram or usage1.VRAM or usage1.vram
                        if type(vram_table) == "table" then
                            raw_vram = vram_table.value or vram_table.Value or 0
                        else
                            raw_vram = vram_table or 0
                        end
                    end
                    local vram = tonumber(raw_vram) or 0
                    processes[#processes + 1] = {name, vram}
                end
            end
        end
        table.sort(processes, function(proc1, proc2) return proc1[2] > proc2[2] end)
        return processes
    else
        return nil
    end
end

--- Internal function to set correct gpu
function data.set_gpu()
    if util.command_exists("nvidia-smi") then
        -- Ensure the driver isn't broken/hanging and successfully finds a GPU
        local check = read_cmd("nvidia-smi -L 2>/dev/null")
        if check and check:match("GPU") then
            data.gpu = "nvidia"
            return true
        end
    elseif util.command_exists("amdgpu_top  --smi") then
        data.gpu = "amd"
        return true
    end
    return false
end

--- Is the given path a mount? (see conky's is_mounted)
-- @string path
-- @treturn boolean
function data.is_mounted(path)
    return "1" == conky_loader:get(5, "${if_mounted %s}1${endif}", path)
end

--- Get the drive usage in percent for the given path.
-- @string path
-- @treturn number
function data.drive_percentage(path)
    return tonumber(conky_loader:get(5, "${fs_used_perc %s}", path))
end

--- Get activity of a drive. If unit is specified the value will be converted
-- to that unit.
-- @string device e.g. sda1
-- @string[opt] mode "read" or "write"; both if nil
-- @string[opt] unit like "B", "MiB", "kB", ...; no conversion if nil
-- @treturn number,string activity, unit
function data.diskio(device, mode, unit)
    local mode = mode and "_" .. mode or ""
    local result = conky_loader:get("${diskio%s /dev/%s}", mode, device)
    local value, parsed_unit = result:match("(%d+%p?%d*) ?(%w+)")
    return convert_unit(parsed_unit, unit, tonumber(value)), unit or parsed_unit
end

--- Detect mount points and their respective devices plus physical devices.
-- @function data.find_devices
-- @treturn table mapping of mount points (paths) to value pairs of
--                (logical) device and physical device
--                e.g. {["/"] = {"sda1", "sda"}}
data.find_devices = util.memoize(10, function()
    local lsblk = read_cmd("lsblk --noheadings --raw --output NAME,TYPE,MOUNTPOINT")
    local rows = lsblk:gmatch("(%S+) (%S*) (%S*)")
    local mounts = {}
    local physical_device
    for device, type, mount in rows do
        print("find_devices:"..device..":"..type..":"..mount)
        if type == "disk" then physical_device = device end
        if mount ~= "" then
            mounts[mount] = {device, physical_device}
        end
    end
    return mounts
end)

--- Get unique mount points with their logical and physical devices.
-- Ensures only one mount point is returned per logical partition device.
-- @treturn table Array of tables containing {mount, device, physical_device}
function data.get_unique_mounts()
    if not has_cjson then
        print("data.get_unique_mounts: cjson is not available.")
        return {}
    end

    local raw_json = read_cmd("lsblk -J")
    if not raw_json or raw_json == "" then
        return {}
    end

    local success, parsed = pcall(cjson.decode, raw_json)
    if not success then
        print("data.get_unique_mounts: Failed to parse JSON: " .. tostring(parsed))
        return {}
    elseif type(parsed) ~= "table" or type(parsed.blockdevices) ~= "table" then
        return {}
    end

    local all_mounts = {}
    local device_to_mounts = {}

    local function is_excluded(mp)
        return mp == "/boot/efi" or mp == "[SWAP]" or mp:match("%.snapshots") or
               mp:match("^/var/lib/") or (mp:match("^/run/") and not mp:match("^/run/media/")) or
               mp:match("^/snap/") or mp:match("^/flatpak/") or mp:match("^/sys/") or
               mp:match("^/proc/") or mp:match("^/dev/")
    end

    local function traverse(node, phys_disk, parent_part)
        if not node then return end
        local name, dtype = node.name, node.type

        if dtype == "disk" then
            phys_disk, parent_part = name, nil
        elseif dtype == "part" then
            parent_part = name
        end

        local dev_store = (dtype ~= "disk" and dtype ~= "part" and parent_part) or name
        local mps = type(node.mountpoints) == "table" and node.mountpoints or {node.mountpoint}

        for _, mp in ipairs(mps) do
            if type(mp) == "string" and mp ~= "" and mp ~= "null" and not is_excluded(mp) then
                all_mounts[mp] = { device = dev_store, physical_device = phys_disk or name }
                device_to_mounts[name] = device_to_mounts[name] or {}
                table.insert(device_to_mounts[name], mp)
            end
        end

        if type(node.children) == "table" then
            for _, child in ipairs(node.children) do
                traverse(child, phys_disk, parent_part)
            end
        end
    end

    for _, device in ipairs(parsed.blockdevices) do
        traverse(device, nil, nil)
    end

    local selected_mounts = {}
    for _, m_list in pairs(device_to_mounts) do
        -- Add string tie-breaker to prevent Lua 5.3+ "invalid order function" crash on duplicates
        table.sort(m_list, function(a, b)
            if #a == #b then return a < b end
            return #a < #b
        end)
        local added = false
        for _, m in ipairs(m_list) do
            if m == "/" or m == "/home" then
                table.insert(selected_mounts, m)
                added = true
            end
        end
        if not added and #m_list > 0 then
            table.insert(selected_mounts, m_list[1])
        end
    end

    table.sort(selected_mounts, function(a, b)
        if #a == #b then return a < b end
        return #a < #b
    end)

    local unique_mounts = {}
    local seen_mounts = {}
    for _, mount in ipairs(selected_mounts) do
        if not seen_mounts[mount] then
            seen_mounts[mount] = true
            local info = all_mounts[mount]
            print("Mounts:" .. mount .. ":" .. info.device .. ":" .. info.physical_device)
            table.insert(unique_mounts, {
                mount = mount,
                device = info.device,
                physical_device = info.physical_device
            })
        end
    end
    return unique_mounts
end


--- Get current HDD/SSD temperatures.
-- Relies on hwmon information in /sys/block. Requires drivetemp kernel module.
-- @function data.device_temperatures
-- @treturn table mapping devices to temperature values
data.device_temperatures = util.memoize(5, function(device)
    local temp_inputs = read_cmd("ls -1"
        --.. " /sys/block/*/device/hwmon/hwmon*/temp1_input"  -- sata
        .. " /sys/block/*/device/hwmon*/temp1_input"  -- nvme
        .. " 2> /dev/null"
    )
    local temps = {}
    for device, hwmon_path in temp_inputs:gmatch("/sys/block/(%w+)/device/(%S+)") do
        hwmon_path = "/sys/block/" .. device .. "/device/" .. hwmon_path
        local r = read_number_from_file(hwmon_path)
        if r then
            temps[device] = read_number_from_file(hwmon_path) / 1000
        end
    end
    return temps
end)


--- DEPRECATED; Get current HDD/SSD temperatures.
-- Relies on hddtemp to be running daemon mode. The results depend on what
-- hddtemp reports and may require manual configuration,
-- e.g. via /etc/default/hddtemp
-- For experimental NVME support, requires "nvme smart-log" to be available
-- and added as an exception in sudoers, hddtemp does not support NVME.
--
-- Since hddtemp is unmaintained and nvme support has been added to the kernel
-- this function is deprecated. -> use data.device_temperatures
--
-- @function data.hddtemp
-- @treturn table mapping devices to temperature values
data.hddtemp = util.memoize(5, function()
    local hddtemp = read_cmd("nc localhost 7634 -d")
    local temperatures = {}
    for device, temp in hddtemp:gmatch("|([^|]+)|[^|]+|(%d+)|C|") do
        temperatures[device] = tonumber(temp)
    end

    -- experimental: nvme drives, currently requires sudo
    local lsblk = read_cmd("lsblk --nodeps --noheadings --paths --output NAME")
    for device in lsblk:gmatch("/dev/nvme%S+") do
        local nvme = read_cmd(("sudo nvme smart-log '%s'"):format(device))
        temperatures[device] = tonumber(nvme:match("temperature%s+: (%d+) C"))
    end
    return temperatures
end)

function data.get_active_network_interface()
    local output = read_cmd("ip -br link show")
    local wired_interfaces = {}
    local wireless_interfaces = {}
    local unknown_interfaces = {}

    for line in output:gmatch("([^\n]+)") do
        local name, state, _ = line:match("^%s*(%S+)%s+(%S+)%s+.*")

        if name and state == "UP" then
            -- Ignore loopback devices
            if name == "lo" then
                goto continue
            end

            -- Ignore tunnel devices (e.g., tun0)
            if name:match("^tun") then
                goto continue
            end

            -- Ignore VLANs (e.g., eth0.100, enp1s0.200)
            if name:match("%.%d+$") then
                goto continue
            end

            -- Ignore bridges (e.g., br0, docker0)
            if name:match("^br") or name:match("^docker") then
                goto continue
            end

            -- Categorize as wired or wireless based on common prefixes
            if name:match("^(eth|enp|pci)") then -- Common wired prefixes
                table.insert(wired_interfaces, name)
            elseif name:match("^(wlan|wlp|wifi|ra|mlan)") then -- Common wireless prefixes (added ra, mlan for broader coverage)
                table.insert(wireless_interfaces, name)
            else -- Fallback for other active, non-ignored interfaces
                table.insert(unknown_interfaces, name)
            end
        end
        ::continue::
    end

    -- Prioritize wired interfaces over wireless
    return wired_interfaces[1] or wireless_interfaces[1] or unknown_interfaces[1] or nil
end

--- Get the IP address of the active network interface.
-- Uses `data.get_active_network_interface` to determine the interface.
-- @treturn string|nil The IP address, or nil if no active interface or IP found.
function data.get_active_network_address()
    local active_interface = data.get_active_network_interface()
    if active_interface then

        local ip_address = conky_loader:get("${addr %s}", active_interface)
        return ip_address 
    end
    return ""
end

--- Get volume of down- and uploaded data since last conky update cycle.
-- @string interface e.g. "eth0"
-- @treturn number,number downspeed and upspeed in KiB
function data.network_speed(interface)
    local result = conky_loader:get("${downspeedf %s}|${upspeedf %s}", interface, interface)
    return unpack(util.map(tonumber, result:gmatch("%d+%p?%d*")))
end



return data
