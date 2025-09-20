--- A collection of Image classes
-- @module widget_image
-- @alias wi

pcall(function() require('cairo') end)
pcall(function() require('imlib2') end)
pcall(function() require('cairo_imlib2_helper') end)

local data = require('src/data')
local util = require('src/util')
local ch = require('src/cairo_helpers')
local core = require('src/widgets/core')
local Widget = core.Widget

-- lua 5.1 to 5.3 compatibility
local unpack = unpack or table.unpack  -- luacheck: read_globals unpack table
local floor, ceil, clamp = math.floor, math.ceil, util.clamp


--- Common (abstract) base class for `StaticImage` and `Whatever Else`.
-- @type Image
local Image = util.class(Widget)
w.Image = Image
function Image:init(args)
    assert(getmetatable(self) ~= Image, "Cannot instanciate class Image directly.")
end

function Image:layout(width, height)
    self.width = width
    self.height = height
end
--- Draw an unchangeable image.
-- Use this widget for images that will never be updated.
-- @type Image
local StaticImage = util.class(Widget)
w.StaticImage = StaticImage

--- @string path image to be displayed.
-- @tparam ?table args table of options, see `Image:init`
-- @tparam ?boolean args.fixed_size if true the image won't be scaled.
function StaticImage:init(path, args)
    Image.init(self, args)

    self._fixed_size = args.fixed_size or false
    self._path = path

    -- use imlib to find image size
    self._image = imlib_load_image(self._path)
    imlib_context_set_image(self._image)
    self._image_width = imlib_image_get_width()
    self._image_height = imlib_image_get_height()

    if self._fixed_size then
        self.width = self._image_width
        self.height = self._image_height
    else
        self._min_width = self._image_width
        self._min_height = self._image_height
    end
end

function StaticImage:layout(width, height)
    self.width = width
    self.height = height
end

function StaticImage:render(cr)
    if self._image == nil then return end

    local scale_width = self.width/self._image_width
    local scale_height = self.height/self._image_height

    -- Scale by the larger ammount (smaller number) to maintain aspect ratio
    local scale = 1.0
    if scale_width < scale_height then
        scale = scale_width
    else
        scale = scale_height
    end
    -- If scale is greater then 1 center rather then expand, in the future
    -- this could be an option
    local x=0
    local y=0
    if scale > 1.0 then
        x = (self.width-self._image_width)/2
        y = (self.height-self._image_height)/2
        scale = 1.0
    end
    cairo_draw_image(self._path, cairo_get_target(cr), x, y, scale, scale)
end

--- Draw an unchangeable image.
-- Use this widget for images that will never be updated.
-- @type Image
local RandomImage = util.class(Widget)
w.RandomImage = RandomImage

--- @string path image to be displayed.
-- @tparam ?table args table of options, see `Image:init`
function RandomImage:init(path, args)
    Image.init(self, args)

    self._image_list = util.files_in_dir(path)

    -- use imlib to find image size
    self._image = nil
    self._current_path = ""
    self._image_width = 0
    self._image_height = 0

    self._tick = 0

    if #self._image_list > 0 then
        math.randomseed(os.time())
        local next_index = math.random(1, #self._image_list)

        -- use imlib to find image size
        self._current_path = self._image_list[next_index]
        print("Image: "..self._current_path)
        self._image = imlib_load_image(self._image_list[next_index])
        imlib_context_set_image(self._image)
        self._image_width = imlib_image_get_width()
        self._image_height = imlib_image_get_height()

        self.width = self._image_width
        self.height = self._image_height
    end
end

function RandomImage:update(update_count)
    if self._tick > 30 then
        self._tick = 0
        if #self._image_list > 0 then
            -- free old image
            imlib_context_set_image(self._image)
            imlib_free_image_and_decache()
            local next_index = math.random(1, #self._image_list)
            -- use imlib to find image size
            self._current_path = self._image_list[next_index]
            print("Image: "..self._current_path)
            self._image = imlib_load_image(self._current_path)
            imlib_context_set_image(self._image)
            self._image_width = imlib_image_get_width()
            self._image_height = imlib_image_get_height()

            self.width = self._image_width
            self.height = self._image_height
        end
        return true
    end

    self._tick = self._tick + 1
end

function RandomImage:layout(width, height)
    self._width = width
    self._height = height
end

function RandomImage:render(cr)

    if self._image == nil then return end

    local scale_width = self._width/self._image_width
    local scale_height = self._height/self._image_height

    -- Scale by the larger ammount (smaller number) to maintain aspect ratio
    local scale = 1.0
    if scale_width < scale_height then
        scale = scale_width
    else
        scale = scale_height
    end
    -- If scale is greater then 1 center rather then expand, in the future
    -- this could be an option
    local x=0
    local y=0
    if scale > 1.0 then
        x = (self._width-self._image_width)/2
        y = (self._height-self._image_height)/2
        scale = 1.0
    else
        x = (self._width-(self._image_width*scale))/2
        y = (self._height-(self._image_height*scale))/2
    end

    cairo_draw_image(self._current_path, cairo_get_target(cr), x, y, scale, scale)
end

return w
