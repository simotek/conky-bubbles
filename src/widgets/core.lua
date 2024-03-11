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

    rgb_colors = {}

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
    self._width = args.width
    self._height = args.height
    self._background_surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                                          args.width,
                                                          args.height)
    self._main_surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                                          args.width,
                                                          args.height)
end

--- Layout all Widgets and cache their backgrounds.
-- Call this once to create the initial layout.
-- Will be called again automatically each time the layout changes.
function Renderer:layout()
    local widgets = self._root:layout(self._width, self._height) or {}
    table.insert(widgets, 1, {self._root, 0, 0, self._width, self._height})

    -- We need to order widgets so that parents are drawn before there children
    -- otherwise frame backgrounds etc will draw on top of the things in frames
    ordered_widgets = {}

    -- There should be one widget with no parent, unfortunately it has
    -- no children set, but other children should have it as the parent
    root_widget = nil
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
    last_list_size = -1
    current_list_size = 0
    found_all_widgets = false

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

    DEBUG = false

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
    end

    cairo_destroy(cr)
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
    mcr = cairo_create(self._main_surface)
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
        DEBUG = false
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
    cairo_paint(mcr);
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
-- @type Widget Widget.parent

--- Called at least once to inform the widget of the width and height
-- it may occupy.
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


--- Basic collection of widgets.
-- Rows are drawn in a vertical stack starting at the top of the drawble
-- surface.
-- @type Rows
local Rows = util.class(Widget)
w.Rows = Rows

--- @tparam {Widget,...} widgets
function Rows:init(widgets)
    self._children = widgets

    local width = 0
    self._min_height = 0
    self._fillers = 0
    self._fixed_height = 0
    for _, widget in ipairs(self._children) do

        widget.parent = self

        if widget.width then
            if widget.width > width then width = widget.width end
        elseif widget._min_width then
            if widget._min_width > width then width = widget._min_width end
        end
        if widget.height ~= nil then
            self._min_height = self._min_height + widget.height
            self._fixed_height = self._fixed_height + widget.height
        elseif widget._min_height then
            self._min_height = self._min_height + widget._min_height
            self._fillers = self._fillers + 1
        else
            self._fillers = self._fillers + 1
        end
    end
    if self._fillers == 0 then
        self.height = self._min_height
    end
    self._min_width = width
end

function Rows:update(update_count)
    local reflow = false

    for _, widget in ipairs(self._children) do
        reflow = widget:update(update_count) or reflow
    end

    if reflow then
        local width = 0
        local new_min_height = 0
        self._fixed_height = 0
        self._fillers = 0
        for _, widget in ipairs(self._children) do

            widget.parent = self

            if widget.width then
                if widget.width > width then width = widget.width end
            elseif widget._min_width then
                if widget._min_width > width then width = widget._min_width end
            end
            if widget.height ~= nil then
                new_min_height = new_min_height + widget.height
                self._fixed_height = self._fixed_height + widget.height
            elseif widget._min_height then
                new_min_height = new_min_height + widget._min_height
                self._fillers = self._fillers + 1
            else
                self._fillers = self._fillers + 1
            end
        end
        if self._fillers == 0 then
            self.height = new_min_height
        end

        -- Design Decision, never shrink because it can look strange
        -- with dynamic content
        if width > self._min_width then
            self._min_width = width
        end
        if new_min_height > self._min_height then
            self._min_height = new_min_height
        end

        return true
    end
end

function Rows:layout(width, height)
    self._width = width  -- used to draw debug lines
    local y = 0
    local children = {}
    local filler_height = (height - self._fixed_height) / self._fillers

    -- Need to handle widgets that may have a min_height higher then the
    -- filler height, loop through until the same number of widgets with the
    -- that have larger min height is found twice, at that point the filler
    -- will be as small as it needs to be
    local last_count = -1
    local this_count = 0

    local actual_fillers = self._fillers
    local height_remaining = height - self._fixed_height

    while filler_height > 0 and last_count ~= this_count do
        last_count = this_count
        this_count = 0
        for _, widget in ipairs(self._children) do
            if widget._min_height then
                if widget._min_height > filler_height then
                    this_count = this_count + 1
                    actual_fillers = actual_fillers + 1
                    height_remaining = height_remaining - widget._min_height
                end
            end
        end
        filler_height = height_remaining / actual_fillers
    end
    for _, widget in ipairs(self._children) do
        local widget_height = filler_height
        if widget.height then
            widget_height = widget.height
        elseif widget._min_height then
            if widget._min_height > filler_height then
                widget_height = widget._min_height
            end
        end
        table.insert(children, {widget, 0, y, width, widget_height})
        local sub_children = widget:layout(width, widget_height) or {}
        for _, child in ipairs(sub_children) do
            child[3] = child[3] + y
            table.insert(children, child)
        end
        y = y + widget_height
    end
    return children
end

--- Display Widgets side by side
-- @type Columns
local Columns = util.class(Widget)
w.Columns = Columns

-- reuse an identical function

--- @tparam {Widget,...} widgets
function Columns:init(widgets)
    self._children = widgets

    self._min_width = 0
    self._fillers = 0
    self._fixed_width = 0
    local height = 0
    local fix_height = false
    for _, widget in ipairs(self._children) do
        widget.parent = self

        if widget.width ~= nil then
            self._min_width = self._min_width + widget.width
            self._fixed_width  = self._fixed_width + widget.width
        elseif widget._min_width then
            self._min_width = self._min_width + widget._min_width
            self._fillers = self._fillers + 1
        else
            self._fillers = self._fillers + 1
        end
        if widget.height then
            fix_height = true
            if widget.height > height then height = widget.height end
        elseif widget._min_height then
            if widget._min_height > height then height = widget._min_height end
        end
    end
    if self._fillers == 0 then
        self.width = self._min_width
    end
    if fix_height then
        self.height = height
    end
    self._min_height = height
end

function Columns:update(update_count)
    local reflow = false

    for _, widget in ipairs(self._children) do
        reflow = widget:update(update_count) or reflow
    end

    if reflow then
        self._fillers = 0
        self._fixed_width = 0
        local new_min_width = 0
        local height = 0
        local fix_height = false
        for _, widget in ipairs(self._children) do
            if widget.width ~= nil then
                new_min_width = new_min_width + widget.width
                self._fixed_width = self._fixed_width + widget.width
            elseif widget._min_width then
                new_min_width = new_min_width + widget._min_width
                self._fillers = self._fillers + 1
            else
                self._fillers = self._fillers + 1
            end
            if widget.height then
                fix_height = true
                if widget.height > height then height = widget.height end
            elseif widget._min_height then
                if widget._min_height > height then height = widget._min_height end
            end
        end
        if self._fillers == 0 then
            self.width = new_min_width
        end
        if fix_height then
            self.height = height
        end

        -- Design Decision, never shrink because it can look strange
        -- with dynamic content
        if new_min_width > self._min_width then
            self._min_width = new_min_width
        end
        if height > self._min_height then
            self._min_height = height
        end

        return true
    end
end

function Columns:layout(width, height)
    self._height = height  -- used to draw debug lines
    local x = 0
    local children = {}
    local filler_width = (width - self._fixed_width) / self._fillers

    -- Need to handle widgets that may have a min_height higher then the
    -- filler height, loop through until the same number of widgets with the
    -- that have larger min height is found twice, at that point the filler
    -- will be as small as it needs to be
    local last_count = -1
    local this_count = 0

    local actual_fillers = self._fillers
    local width_remaining = width - self._fixed_width

    while filler_width > 0 and last_count ~= this_count do

        last_count = this_count
        this_count = 0
        for _, widget in ipairs(self._children) do
            if widget._min_width then
                if widget._min_width > filler_width then
                    this_count = this_count + 1
                    actual_fillers = actual_fillers + 1
                    width_remaining = width_remaining - widget._min_width
                end
            end
        end
        filler_width = width_remaining / actual_fillers
    end

    for _, widget in ipairs(self._children) do
        local widget_width = filler_width
        if widget.width then
            widget_width = widget.width
        elseif widget._min_width then
            if widget._min_width > filler_width then
                widget_width = filler_width
            end
        end
        table.insert(children, {widget, x, 0, widget_width, height})
        local sub_children = widget:layout(widget_width, height) or {}
        for _, child in ipairs(sub_children) do
            child[2] = child[2] + x
            table.insert(children, child)
        end
        x = x + widget_width
    end
    return children
end

--- Leave space between widgets.
-- If either height or width is not specified, the available space
-- inside a Rows or Columns widget will be distributed evenly between Fillers
-- with no fixed height/width.
-- A Filler may contain one other Widget which will have its dimensions
-- restricted to those of the Filler.
-- @type Filler
local Filler = util.class(Widget)
w.Filler = Filler

--- @tparam ?table args table of options
-- @tparam ?int args.width
-- @tparam ?int args.height
-- @tparam ?Widget args.widget
function Filler:init(args)
    if args then
        self._widget = args.widget
        self.height = args.height or (self._widget and self._widget.height)
        self.width = args.width or (self._widget and self._widget.width)
    end
end

function Filler:layout(width, height)
    if self._widget then
        local children = self._widget:layout(width, height) or {}
        table.insert(children, 1, {self._widget, 0, 0, width, height})
        return children
    end
end


local function side_widths(arg)
    arg = arg or 0
    if type(arg) == "number" then
        return {top=arg, right=arg, bottom=arg, left=arg}
    elseif #arg == 2 then
        return {top=arg[1], right=arg[2], bottom=arg[1], left=arg[2]}
    elseif #arg == 3 then
        return {top=arg[1], right=arg[2], bottom=arg[3], left=arg[2]}
    elseif #arg == 4 then
        return {top=arg[1], right=arg[2], bottom=arg[3], left=arg[4]}
    end
end


--- Draw a static border and/or background around/behind another widget.
-- @type Frame
local Frame = util.class(Widget)
w.Frame = Frame

--- @tparam Widget widget Widget to be wrapped
-- @tparam table args table of options
-- @tparam ?number|{number,...} args.padding Leave some space around the inside
--  of the frame.<br>
--  - number: same padding all around.<br>
--  - table of two numbers: {top & bottom, left & right}<br>
--  - table of three numbers: {top, left & right, bottom}<br>
--  - table of four numbers: {top, right, bottom, left}
-- @tparam ?number|{number,...} args.margin Like padding but outside the border.
-- @tparam ?{number,number,number,number} args.background_color
-- @tparam ?{string} args.background_image path to background image
-- @tparam[opt=transparent] ?{number,number,number,number} args.border_color
-- @tparam[opt=0] ?number args.border_width border line width
-- @tparam ?{string,...} args.border_sides any combination of
--                                         "top", "right", "bottom" and/or "left"
--                                         (default: all sides)
function Frame:init(widget, args)
    self._widget = widget
    widget.parent = self
    self._background_color = args.background_color or nil
    self._background_image = args.background_image or nil
    self._background_image_alpha = args.background_image_alpha or 1.0
    self._border_color = args.border_color or {0, 0, 0, 0}
    self._border_width = args.border_width or 0

    self._padding = side_widths(args.padding)
    self._margin = side_widths(args.margin)
    self._border_sides = util.set(args.border_sides or {"top", "right", "bottom", "left"})

    self._has_background = self._background_color and self._background_color[4] > 0
    self._has_background_image = self._background_image
    self._has_border = self._border_width > 0
                       and (not args.border_sides or #args.border_sides > 0)

    self._x_left = self._margin.left + self._padding.left
                   + (self._border_sides.left and self._border_width or 0)
    self._y_top = self._margin.top + self._padding.top
                  + (self._border_sides.top and self._border_width or 0)
    self._x_right = self._margin.right + self._padding.right
                    + (self._border_sides.right and self._border_width or 0)
    self._y_bottom = self._margin.bottom + self._padding.bottom
                     + (self._border_sides.bottom and self._border_width or 0)

    if self._has_background_image then
        -- use imlib2 to calc background image size
        imlib2img = imlib_load_image(self._background_image)
        if self._background_image == nil then
            self._has_background_image = false
            print("Error: Bubbles Frame: Couldn't load background image"..self._background_image)
        else
            imlib_context_set_image(imlib2img)
            self._background_image_width = imlib_image_get_width()
            self._background_image_height = imlib_image_get_height()
            imlib_free_image()
        end
    end


    if widget.width then
        self.width = widget.width + self._x_left + self._x_right
    else
        widget_min_w = self._widget._min_width or 0
        self._min_width = widget_min_w + self._x_left + self._x_right
    end
    if widget.height then
        self.height = widget.height + self._y_top + self._y_bottom
    else
        widget_min_h = self._widget._min_height or 0
        self._min_height = widget_min_h + self._y_top + self._y_bottom
    end
end

function Frame:update(update_count)
    local reflow = false
    reflow = self._widget:update(update_count) or reflow

    if reflow then
        if self._widget.width then
            self.width = self._widget.width + self._x_left + self._x_right
        else
            widget_min_w = self._widget._min_width or 0
            self._min_width = widget_min_w + self._x_left + self._x_right
        end
        if self._widget.height then
            self.height = self._widget.height + self._y_top + self._y_bottom
        else
            widget_min_h = self._widget._min_height or 0
            self._min_height = widget_min_h + self._y_top + self._y_bottom
        end
        return true
    end
end

function Frame:layout(width, height)
    self._width = width - self._margin.left - self._margin.right
    self._height = height - self._margin.top - self._margin.bottom
    local inner_width = width - self._x_left - self._x_right
    local inner_height = height - self._y_top - self._y_bottom
    local children = self._widget:layout(inner_width, inner_height) or {}
    for _, child in ipairs(children) do
        child[2] = child[2] + self._x_left
        child[3] = child[3] + self._y_top
    end
    table.insert(children, 1, {self._widget, self._x_left, self._y_top, inner_width, inner_height})
    return children
end

function Frame:render_background(cr)
    if self._has_background_image then
        cairo_place_image(self._background_image, cr, 0, 0, self._width, self._height, self._background_image_alpha)
    elseif self._has_background then
        cairo_rectangle(cr, self._margin.left, self._margin.top, self._width, self._height)
        cairo_set_source_rgba(cr, unpack(self._background_color))
        cairo_fill(cr)
    end

    if self._has_border then
        cairo_set_antialias(cr, CAIRO_ANTIALIAS_NONE)
        cairo_set_line_cap(cr, CAIRO_LINE_CAP_SQUARE)
        cairo_set_source_rgba(cr, unpack(self._border_color))
        cairo_set_line_width(cr, self._border_width)
        local x_min = self._margin.left + 0.5 * self._border_width
        local y_min = self._margin.top + 0.5 * self._border_width
        local x_max = self._margin.left + self._width - 0.5 * self._border_width
        local y_max = self._margin.top + self._height - 0.5 * self._border_width
        local side, line, move = self._border_sides, cairo_line_to, cairo_move_to
        cairo_move_to(cr, x_min, y_min);
        (side.top and line or move)(cr, x_max, y_min);
        (side.right and line or move)(cr, x_max, y_max);
        (side.bottom and line or move)(cr, x_min, y_max);
        (side.left and line or move)(cr, x_min, y_min);
        cairo_stroke(cr, self._background_color)
    end
end

return w
