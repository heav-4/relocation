local M = {}
local ui = require("ui")
local settings = require("settings")

function M.HSL(h, s, l, a) -- not mine.
	if s<=0 then return l,l,l,a end
	h, s, l = h*6, s, l
	local c = (1-math.abs(2*l-1))*s
	local x = (1-math.abs(h%2-1))*c
	local m,r,g,b = (l-.5*c), 0,0,0
	if h < 1     then r,g,b = c,x,0
	elseif h < 2 then r,g,b = x,c,0
	elseif h < 3 then r,g,b = 0,c,x
	elseif h < 4 then r,g,b = 0,x,c
	elseif h < 5 then r,g,b = x,0,c
	else              r,g,b = c,0,x
	end return r+m, g+m, b+m, a
end
M.visual_tile_spacing = 100
M.tile_size = 4/5
M.tile_border = 3/50
M.tile_spacing = 1
M.cx, M.cy = 0, 0
M.zoom = M.visual_tile_spacing
M.zx = 0
M.zy = 0
M.vwheelpos = (math.log(M.zoom)/math.log(2))*5
M.wheelpos = 0
M.wheelpos_offset = (math.log(M.zoom)/math.log(2))*5
local font_size = (M.tile_size-M.tile_border/2)/2*M.visual_tile_spacing
M.font = love.graphics.setNewFont(font_size)

local flash_sine = 0
local frames = 0

function M.pos_to_tile(mx, my, offset)
    offset = offset or 0
    mx, my = M.board_space(mx, my)
    mx, my = mx + M.tile_size/2, my + M.tile_size/2
    mx, my = mx + (M.tile_spacing-M.tile_size)/2, my + (M.tile_spacing-M.tile_size)/2
    mx, my = mx / M.tile_spacing, my / M.tile_spacing
    return math.floor(mx + offset), math.floor(my + offset)
end

local function camera_transform()
    local w, h = love.graphics.getDimensions()
    local trans = love.math.newTransform()
    trans:translate(w/2, h/2)
    trans:scale(M.zoom)
    trans:translate(-M.cx, -M.cy)
    return trans
end
function M.screen_space(bx, by)
    local trans = camera_transform()
    return trans:transformPoint(sx, sy)
end
function M.board_space(sx, sy)
    local trans = camera_transform()
    return trans:inverseTransformPoint(sx, sy)
end

local function tile_pos(x, y)
    return x * M.tile_spacing - M.tile_size / 2, y * M.tile_spacing - M.tile_size / 2
end

local function tile_pos_center(x, y)
    local tx, ty = tile_pos(x, y)
    return tx + M.tile_size / 2, ty + M.tile_size/2
end

local top_text = ""
local top_time = 0
local top_font = love.graphics.newFont(30)
local top_burst = 0

local function draw_top_text()
    if top_time > 0 then top_time = top_time - 1 end
    if top_burst > 0 then top_burst = top_burst - 1 end
    local w, h = love.graphics.getDimensions()
    local text_y = 100
    local text_alpha = (top_time>140 and 0.8+(0.2-top_burst/50) or top_time/140)
    love.graphics.setColor(1, 1, 1, text_alpha)
    local old_font = love.graphics.getFont()
    love.graphics.setFont(top_font)
    love.graphics.printf(top_text, 0, text_y, w, "center")
    love.graphics.setFont(old_font)
end

function M.text(text)
    top_text = text
    top_time = 240
    top_burst = 10
end

local function render_tile(t)
    local tile_x = t.x * M.tile_spacing - M.tile_size/2
    local tile_y = t.y * M.tile_spacing - M.tile_size/2
    local tile_mx = tile_x + M.tile_size
    local tile_my = tile_y + M.tile_size
    love.graphics.setColor(t.r, t.g, t.b)
    if settings.shapeonly then
        local h, s, l = M.HSL((frames/360)%1, 0.7, 0.3)
        love.graphics.setColor(h, s, l)
    end
    love.graphics.rectangle("fill", tile_x, tile_y, M.tile_size, M.tile_size)
    love.graphics.setColor(0, 0, 0)
    local text_x = tile_x
    local text_y = tile_y + M.tile_size/2 - M.font:getHeight()/M.visual_tile_spacing/2
    if not settings.shapeonly then
        love.graphics.printf(t.text, text_x, text_y, M.tile_size*M.visual_tile_spacing, "center", 0, 1/M.visual_tile_spacing)
    end
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(M.tile_border)
    love.graphics.polygon("line", tile_x, tile_y, tile_mx, tile_y, tile_mx, tile_my, tile_x, tile_my)
end

local function render_tile_selection(x, y, x2, y2, r, g, b, a)
    a = a or 1
    local tile_x = x * M.tile_spacing - M.tile_size/2 - M.tile_border
    local tile_y = y * M.tile_spacing - M.tile_size/2 - M.tile_border
    local tile_mx = tile_x + M.tile_spacing*(x2-x) + M.tile_size + M.tile_border*2
    local tile_my = tile_y + M.tile_spacing*(y2-y) + M.tile_size + M.tile_border*2
    love.graphics.setColor(r, g, b, a)
    love.graphics.setLineWidth(M.tile_border)
    love.graphics.polygon("line", tile_x, tile_y, tile_mx, tile_y, tile_mx, tile_my, tile_x, tile_my)
end

local function render_plus(x, y, r, g, b, a)
    a = a or 1
    local tile_x = x * M.tile_spacing
    local tile_y = y * M.tile_spacing
    local plus_size = M.tile_spacing*3/4
    love.graphics.setColor(r, g, b, a)
    love.graphics.setLineWidth(M.tile_border)
    love.graphics.line(tile_x, tile_y + plus_size/2, tile_x, tile_y - plus_size/2)
    love.graphics.line(tile_x + plus_size/2, tile_y, tile_x - plus_size/2, tile_y)
end

local function render_grid()
    local w, h = love.graphics.getDimensions()
    local left, top = M.board_space(0, 0)
    local right, bottom = M.board_space(w, h)
    love.graphics.setLineWidth(1/M.zoom)
    love.graphics.setColor(0.2, 0.2, 0.2)
    for x=math.floor(left), math.ceil(right) do
        love.graphics.line(x-.5, top-.5, x-.5, bottom+.5)
    end
    for y=math.floor(top), math.ceil(bottom) do
        love.graphics.line(left-.5, y-.5, right+.5, y-.5)
    end
end 

-- i want to zoom in to the cursor specifically, not the center of the screen.
-- this does that.
local function zoom_camera_drift()
    M.vwheelpos = M.vwheelpos - (M.vwheelpos-M.wheelpos-M.wheelpos_offset)/5
    local new_zoom = 2^(M.vwheelpos/5)
    local zoom_factor = new_zoom/M.zoom
    local trans = love.math.newTransform()
    trans:translate(M.zx, M.zy)
    trans:scale(zoom_factor)
    trans:translate(-M.zx, -M.zy)
    M.cx, M.cy = trans:inverseTransformPoint(M.cx, M.cy)
    M.zoom = new_zoom
end

local function render_tile_preview(world)
    local mx, my = love.mouse.getPosition()
    local sw = world.sw
    local mcx, mcy = M.pos_to_tile(mx, my, -(sw-1)/2)
    if world.currently_moving == nil and world:valid_block(mcx, mcy) then
        render_tile_selection(mcx, mcy, mcx+sw-1, mcy+sw-1, 0, 0.5, 1)
    elseif world.currently_moving ~= nil then
        render_tile_selection(world.currently_moving[1], world.currently_moving[2], world.currently_moving[1]+sw-1, world.currently_moving[2]+sw-1, 0, 1, 0)
        if world:valid_destination(mcx, mcy) then
            render_tile_selection(mcx, mcy, mcx+sw-1, mcy+sw-1, 1, 0, 1)
        elseif world:can_swap(world.currently_moving[1], world.currently_moving[2], mcx, mcy) then
            render_tile_selection(mcx, mcy, mcx+sw-1, mcy+sw-1, 1, 1, 1-flash_sine)
        end
    end
end

local function render_valid_moves(world)
    local offset = math.floor(world.sw/2)
    local voffset = (world.sw-1)/2
    for _, v in ipairs(world.valid_moves) do
        local occupied = false
        if world.sw % 2 == 0 then
            for xo = -1, 0 do
                for yo = -1, 0 do
                    if world:get(v[1]+offset+xo, v[2]+offset+yo) ~= nil then
                        occupied = true
                        break
                    end
                end
            end
            render_plus(v[1]+voffset, v[2]+voffset, 1, 1, 1, occupied and flash_sine/1.5 or 0.2)
        else
            occupied = (world:get(v[1]+offset, v[2]+offset) ~= nil)
            render_tile_selection(v[1]+voffset, v[2]+voffset, v[1]+voffset, v[2]+voffset, 1, 1, 1, occupied and flash_sine/1.5 or 0.2)
        end
    end
end

function M.draw(world)
    local w, h = love.graphics.getDimensions()
    frames = frames + 1
    flash_sine = (math.sin(math.pi*4*frames/60)/4)+3/4
    zoom_camera_drift()
    love.graphics.push()
    love.graphics.applyTransform(camera_transform())
    if settings.grid then render_grid() end
    for _, tile in pairs(world.tiles) do
        render_tile(tile)
    end
    render_tile_preview(world)
    if world.valid_moves then render_valid_moves(world) end
    love.graphics.pop()
    draw_top_text()
    if ui.is_open then ui.render() end
end

return M