--- A collection of Widget classes
-- @module widget_core
-- @alias wc

pcall(function() require('cairo') end)
pcall(function() require('imlib2') end)

local data = require('src/data')
local util = require('src/util')
local ch = require('src/cairo_helpers')

-- lua 5.1 to 5.3 compatibility
local unpack = unpack or table.unpack  -- luacheck: read_globals unpack table

local sin, cos, tan, PI = math.sin, math.cos, math.tan, math.pi
local floor, ceil, clamp = math.floor, math.ceil, util.clamp

-- abort with an error if no theme is set
if not current_theme then
    error("No Theme Set, please set the current_theme variable")
end

w = {}
--- Generate a temperature based color.
-- Colors are chosen based on float offset in a pre-defined color gradient.
-- @number temperature current temperature (or any other type of numeric value)
-- @number low threshold for lowest temperature / coolest color
-- @number high threshold for highest temperature / hottest color
function w.temperature_color(temperature, low, high)
    -- defaults in case temperature is nil
    local cool = ch.convert_string_to_rgba(current_theme.temperature_colors[1])
    local hot = ch.convert_string_to_rgba(current_theme.temperature_colors[1])
    local weight = 0

    local rgb_colors = {}

    for i,v in ipairs(current_theme.temperature_colors) do
        rgb_colors[i] = ch.convert_string_to_rgba(v)
    end

    if type(temperature) == "number" and temperature > -math.huge and temperature < math.huge then
        local idx = (temperature - low) / (high - low) * (#rgb_colors - 1) + 1
        weight = idx - floor(idx)
        cool = rgb_colors[clamp(1, #rgb_colors, floor(idx))]
        hot = rgb_colors[clamp(1, #rgb_colors, ceil(idx))]
    end
    return cool[1] + weight * (hot[1] - cool[1]),
           cool[2] + weight * (hot[2] - cool[2]),
           cool[3] + weight * (hot[3] - cool[3])
end

--- Root widget wrapper
-- Takes care of managing layout reflows and background caching.
-- @type Renderer
local Renderer = util.class()
w.Renderer = Renderer

---
-- @tparam table args table of options
-- @tparam Widget args.root The Widget subclass that should be rendered,
--                          usually a Rows widget
-- @int args.width Width of the surface that should be covered
-- @int args.height Height of the surface that should be covered
function Renderer:init(args)
    self._root = args.root
    self._width = conky_window.width
    self._height = conky_window.height
    self._background_surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                                                self._width,
                                                                self._height)
    self._main_surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                                                self._width,
                                                                self._height)
end

--- Layout all Widgets and cache their backgrounds.
-- Call this once to create the initial layout.
-- Will be called again automatically each time the layout changes.
function Renderer:layout()

    if 1 then
        local size_changed = false
        if (conky_window.width > 0 and
            conky_window.width ~= self._width) then
            self._width = conky_window.width
            size_changed = true
        end

        if (conky_window.height > 0 and 
            conky_window.height ~= self._height) then
            self._height = conky_window.height
            size_changed = true
        end

        if size_changed then
            print("Window: "..conky_window.width..","..conky_window.height)
            print("Window: "..self._width..","..self._height)

            cairo_surface_destroy(self._background_surface)
            self._background_surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                                                self._width,
                                                                self._height)
            cairo_surface_destroy(self._main_surface)
            self._main_surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                                                self._width,
                                                                self._height)
        end
    end

    local widgets = self._root:layout(self._width, self._height) or {}
    table.insert(widgets, 1, {self._root, 0, 0, self._width, self._height})

    -- We need to order widgets so that parents are drawn before there children
    -- otherwise frame backgrounds etc will draw on top of the things in frames
    local ordered_widgets = {}

    -- There should be one widget with no parent, unfortunately it has
    -- no children set, but other children should have it as the parent
    local root_widget = nil
    for w, x, y, _width, _height in util.imap(unpack, widgets) do
        if not w.parent then
            table.insert(ordered_widgets, {w, x, y, _width, _height})
            if root_widget == nil then
                root_widget = w
            else
                print("Error: Multiple Roots")
            end
        end
    end

    -- Insert the first level of children into the list, they will have
    -- the root widget as there parent
    for w, x, y, _width, _height  in util.imap(unpack, widgets) do
        if w.parent == root_widget then
            if not util.in_table(w, ordered_widgets) then
                table.insert(ordered_widgets, {w, x, y, _width, _height})
            end
        end
    end

    -- Go through list and keep adding children if they aren't in list
    -- until there are no more to add or the list stops growing
    local last_list_size = -1
    local current_list_size = 0
    local found_all_widgets = false

    while last_list_size ~= current_list_size and not found_all_widgets do
        last_list_size = current_list_size
        current_list_size = 0
        for w in util.imap(unpack, widgets) do
            current_list_size = current_list_size + 1
            if w._children then
                for _, c in pairs(w._children) do
                    if not util.in_table(c, ordered_widgets) then
                        for wt, x, y, _width, _height in util.imap(unpack, widgets) do
                            if c == wt then
                                table.insert(ordered_widgets, {wt, x, y, _width, _height})
                            end
                        end
                    end
                end
            end
        end
    end

    -- This shouldn't happen but just in case
    for w, x, y, _width, _height in util.imap(unpack, widgets) do
        if not util.in_table(w, ordered_widgets) then
            table.insert(ordered_widgets, {w, x, y, _width, _height})
        end
    end

    self._background_widgets = {}
    self._update_widgets = {}
    self._render_widgets = {}

    local DEBUG = false

    for widget, x, y, _width, _height in util.imap(unpack, ordered_widgets) do

        if widget.render_background then
            local wsr = cairo_surface_create_for_rectangle(self._background_surface,
                            floor(x),floor(y),floor(_width),floor(_height))
            table.insert(self._background_widgets, {widget, wsr})
        end
        if widget.render then
            local wsr = cairo_surface_create_for_rectangle(self._main_surface,
                            floor(x),floor(y),floor(_width),floor(_height))
            table.insert(self._render_widgets, {widget, wsr, floor(_width),floor(_height)})
        end
        if widget.update then
            table.insert(self._update_widgets, widget)
        end
    end

    local bcr = cairo_create(self._background_surface)
    -- clear surface
    cairo_save(bcr)
    cairo_set_source_rgba(bcr, 0, 0, 0, 0)
    cairo_set_operator(bcr, CAIRO_OPERATOR_SOURCE)
    cairo_paint(bcr)
    cairo_restore(bcr)
    cairo_destroy(bcr)

    -- render to backgrounds to surface
    for widget, wsr in util.imap(unpack, self._background_widgets) do
        local wcr = cairo_create(wsr)
        cairo_save(wcr)
        widget:render_background(wcr)
        cairo_restore(wcr)
        cairo_destroy(wcr)
    end

    DEBUG = false
    if DEBUG then
        local cr = cairo_create(wsr)
        --local version_info = table.concat{"conky ", conky_version,
        --                                  "    ", _VERSION,
        --                                  "    cairo ", cairo_version_string()}
        cairo_set_source_rgba(cr, 1, 0, 0, 1)
        --ch.set_font(cr, "Ubuntu", 8)
        --ch.write_left(cr, 0, 8, version_info)
        for _, x, y, width, height in util.imap(unpack, widgets) do
            if width * height ~= 0 then
                cairo_rectangle(cr, x, y, width, height)
            end
        end
        cairo_set_line_width(cr, 1)
        cairo_set_antialias(cr, CAIRO_ANTIALIAS_NONE)
        cairo_set_source_rgba(cr, 1, 0, 0, 0.33)
        cairo_stroke(cr)
        cairo_destroy(cr)
    end
end

--- Update all Widgets
-- @int update_count Conky's $updates
function Renderer:update(update_count)
    local reflow = false
    for _, widget in ipairs(self._update_widgets) do
        if not widget.parent then
            reflow = widget:update(update_count) or reflow
        end
    end
    if reflow then
        -- TBD: This was being called everytime
        -- self:layout()
    end
end

function Renderer:paint_background(cr)
    --cairo_set_source_surface(cr, self._background_surface, 0, 0)
    --cairo_paint(cr)
    -- Layout was being called everytime
    self:layout()
end

--- Render to the given context
-- @tparam cairo_t cr
function Renderer:render(cr)
    -- It doesn't render without these two lines
    cairo_set_source_surface(cr, self._main_surface, 0, 0)
    cairo_paint(cr)
    local mcr = cairo_create(self._main_surface)
    cairo_save(mcr)
    -- Clear previous render for transparent widgets
    cairo_set_source_rgba(mcr, 0, 0, 0, 0)
    cairo_set_operator(mcr, CAIRO_OPERATOR_SOURCE)
    cairo_paint(mcr)
    cairo_restore(mcr)
    -- Overlay background surface
    cairo_set_operator(mcr, CAIRO_OPERATOR_OVER);
    cairo_set_source_surface(mcr, self._background_surface, 0, 0);
    cairo_paint(mcr)
    cairo_restore(mcr)

    -- render forground widgets
    for widget, wsr, _width, _height in util.imap(unpack, self._render_widgets) do
        local wcr = cairo_create(wsr)
        -- This one
        local DEBUG = false
        if DEBUG then
            cairo_set_source_rgba(wcr, 1, 0, 0, 1)
            if _width * _height ~= 0 then
                cairo_rectangle(wcr, 1, 1, _width-1, _height-1)
                cairo_set_line_width(wcr, 1)
                cairo_set_antialias(wcr, CAIRO_ANTIALIAS_NONE)
                cairo_set_source_rgba(wcr, 1, 0, 0, 0.33)
                cairo_stroke(wcr)
            end
        end
        widget:render(wcr)
        cairo_destroy(wcr)
    end
    cairo_paint(mcr)
    cairo_destroy(mcr)
end

--- Base Widget class.
-- @type Widget
local Widget = util.class()
w.Widget = Widget

--- Set a width if the Widget should have a fixed width.
-- Omit (=nil) if width should be adjusted dynamically.
-- @int Widget.width

--- Set a height if the Widget should have a fixed height.
-- Omit (=nil) if height should be adjusted dynamically.
-- @int Widget.height

--- If a widget is inside another widget such as a frame or columns, rows
-- Then this will contain that
-- @tparam Widget Widget.parent

--- Called at least once to inform the widget of the width and height it may occupy.
-- @tparam int width
-- @tparam int height
function Widget:layout(width, height) end  -- luacheck: no unused

--- Called at least once to allow the widget to draw static content.
-- @function Widget:render_background
-- @tparam cairo_t cr Cairo context for background rendering
--                    (to be cached by the `Renderer`)

--- Called before each call to `Widget:render`.
-- If this function returns a true-ish value, a reflow will be triggered.
-- Since this involves calls to all widgets' :layout functions,
-- reflows should be used sparingly.
-- @function Widget:update
-- @int update_count Conky's $updates
-- @treturn ?bool true(-ish) if a layout reflow should be triggered, causing
--                all `Widget:layout` and `Widget:render_background` methods
--                to be called again
function Widget:update(update_count) end
--- Called once per update to do draw dynamic content.
-- @function Widget:render
-- @tparam cairo_t cr

return w
