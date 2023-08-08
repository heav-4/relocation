local M = {}

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

M.tile_size = 40
M.tile_border = 3
M.tile_spacing = 50
M.cx, M.cy = 0, 0
M.font = love.graphics.setNewFont((M.tile_size-M.tile_border/2)/2)

function M.pos_to_tile(mx, my, offset)
    offset = offset or 0
    local w, h = love.graphics.getDimensions()
    mx, my = mx + M.tile_size/2, my + M.tile_size/2
    mx, my = mx + (M.tile_spacing-M.tile_size)/2, my + (M.tile_spacing-M.tile_size)/2
    mx, my = mx - (w/2-M.cx), my - (h/2-M.cy)
    mx, my = mx / M.tile_spacing, my / M.tile_spacing
    return math.floor(mx + offset), math.floor(my + offset)
end

local function tile_pos(x, y)
    return x * M.tile_spacing - M.tile_size / 2, y * M.tile_spacing - M.tile_size / 2
end

local function tile_pos_center(x, y)
    local tx, ty = tile_pos(x, y)
    return tx + M.tile_size / 2, ty + M.tile_size/2
end

local function render_tile(t)
    local tile_x = t.x * M.tile_spacing - M.tile_size/2
    local tile_y = t.y * M.tile_spacing - M.tile_size/2
    local tile_mx = tile_x + M.tile_size
    local tile_my = tile_y + M.tile_size
    love.graphics.setColor(t.r, t.g, t.b)
    love.graphics.rectangle("fill", tile_x, tile_y, M.tile_size, M.tile_size)
    love.graphics.setColor(0, 0, 0)
    local text_x = tile_x
    local text_y = tile_y + M.tile_size/2 - M.font:getHeight()/2
    love.graphics.printf(t.text, text_x, text_y, M.tile_size, "center")
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

local top_text = ""
local top_time = 0
local top_font = love.graphics.newFont(30)
local top_burst = 0

local function draw_top_text()
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
local frames = 0

function M.draw(world)
    frames = frames + 1
    if top_time > 0 then top_time = top_time - 1 end
    if top_burst > 0 then top_burst = top_burst - 1 end
    local flash_sine = (math.sin(math.pi*4*frames/60)/4)+3/4
    local w, h = love.graphics.getDimensions()
    love.graphics.translate(w/2-M.cx, h/2-M.cy)
    for _, tile in pairs(world.tiles) do
        render_tile(tile)
    end
    local mx, my = love.mouse.getPosition()
    local sw = world.sw
    local mcx, mcy = M.pos_to_tile(mx, my, -(sw-1)/2)
    if world.currently_moving == nil and world:valid_block(mcx, mcy) then
        render_tile_selection(mcx, mcy, mcx+sw-1, mcy+sw-1, 0, 0.5, 1)
    elseif world.currently_moving ~= nil then
        render_tile_selection(world.currently_moving[1], world.currently_moving[2], world.currently_moving[1]+sw-1, world.currently_moving[2]+sw-1, 0, 1, 0)
        if world:valid_destination(mcx, mcy) then
            render_tile_selection(mcx, mcy, mcx+sw-1, mcy+sw-1, 1, 0, 1)
        end
    end
    if world.valid_moves then
        local offset = math.floor(world.sw/2)
        local voffset = (world.sw-1)/2
        for _, v in ipairs(world.valid_moves) do
            local occupied = (world:get(v[1]+offset, v[2]+offset) ~= nil)
            render_tile_selection(v[1]+voffset, v[2]+voffset, v[1]+voffset, v[2]+voffset, 1, 1, 1, occupied and flash_sine/1.5 or 0.2)
        end
    end
    love.graphics.translate(-w/2+M.cx, -h/2+M.cy)
    draw_top_text()
end

return M