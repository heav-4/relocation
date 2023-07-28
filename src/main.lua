local tiles = {}

function HSL(h, s, l, a)
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

local function get(x, y)
    return tiles[x.." "..y]
end
local function pushoff(x, y)
    local tile = get(x, y)
    if not tile then return false end
    return tile.pushoff
end
local function move(x, y, x2, y2)
    if get(x2, y2) then error("overlap") end
    tiles[x2.." "..y2] = tiles[x.." "..y]
    tiles[x.." "..y] = nil
    tiles[x2.." "..y2].x = x2
    tiles[x2.." "..y2].y = y2
end
local function neighborhood(x, y)
    local i = -1
    return function()
        i = i + 1
        if i > 8 then return nil end
        return x+(i%3-1), y+math.floor(i/3)-1, get(x+(i%3-1), y+math.floor(i/3)-1)
    end
end
local function move_3x3(x, y, x2, y2)
    for ix, iy, tile in neighborhood(x, y) do
        move(ix, iy, ix + x2-x, iy + y2-y)
        tile.pushoff = true
    end
end
local function valid_3x3(x, y)
    for x, y, s in neighborhood(x, y) do
        if not s then return false end
    end
    return true
end
local function valid_destination(x, y)
    for _, _, s in neighborhood(x, y) do if s then return false end end
    for i=-1, 1 do
        if pushoff(x+2, y+i) then return true end
        if pushoff(x-2, y+i) then return true end
        if pushoff(x+i, y+2) then return true end
        if pushoff(x+i, y-2) then return true end
    end
    return false
end
local function tile_name(index)
    local letter = math.floor(index/5)
    local number = (index%5)+1
    letter = ("ABCDE"):sub(letter+1, letter+1)
    return letter..number
end
local function n_xy(n, w, h)
    return n%w, math.floor(n/h)
end
local function xy_n(x, y, w)
    return x%w + y*w
end
local function make_tile(x, y, n)
    local cx, cy = n_xy(n, 5, 5)
    local r, g, b = HSL((cx)/5, 1, 0.5 + (cy+1)/13)
    return {x=x, y=y, n=n, text=tile_name(n), pushoff = true, r=r, g=g, b=b}
end
local function indexed_tile(n)
    local x, y = n_xy(n, 5, 5)
    return make_tile(x, y, n)
end
local function positioned_tile(x, y)
    local n = xy_n(x-2, y-2, 5)
    return make_tile(x, y, n)
end

local tile_size = 40
local tile_border = 3
local tile_spacing = 50
local cx, cy = 0, 0
local font = love.graphics.setNewFont((tile_size-tile_border/2)/2)
local function render_tile(t)
    local tile_x = t.x * tile_spacing - tile_size/2
    local tile_y = t.y * tile_spacing - tile_size/2
    local tile_mx = tile_x + tile_size
    local tile_my = tile_y + tile_size
    love.graphics.setColor(t.r, t.g, t.b)
    love.graphics.rectangle("fill", tile_x, tile_y, tile_size, tile_size)
    love.graphics.setColor(0, 0, 0)
    local text_x = tile_x
    local text_y = tile_y + tile_size/2 - font:getHeight()/2
    love.graphics.printf(t.text, text_x, text_y, tile_size, "center")
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(tile_border)
    love.graphics.polygon("line", tile_x, tile_y, tile_mx, tile_y, tile_mx, tile_my, tile_x, tile_my)
end

local function render_tile_selection(x, y, x2, y2, r, g, b)
    local tile_x = x * tile_spacing - tile_size/2 - tile_border
    local tile_y = y * tile_spacing - tile_size/2 - tile_border
    local tile_mx = tile_x + tile_spacing*(x2-x) + tile_size + tile_border*2
    local tile_my = tile_y + tile_spacing*(y2-y) + tile_size + tile_border*2
    love.graphics.setColor(r, g, b)
    love.graphics.setLineWidth(tile_border)
    love.graphics.polygon("line", tile_x, tile_y, tile_mx, tile_y, tile_mx, tile_my, tile_x, tile_my)

end

local function pos_to_tile(mx, my)
    local w, h = love.graphics.getDimensions()
    mx, my = mx + tile_size/2, my + tile_size/2
    mx, my = mx + (tile_spacing-tile_size)/2, my + (tile_spacing-tile_size)/2
    mx, my = mx - (w/2-cx), my - (h/2-cy)
    mx, my = mx / tile_spacing, my / tile_spacing
    return math.floor(mx), math.floor(my)
end

local currently_moving = nil
function love.draw()
    local w, h = love.graphics.getDimensions()
    love.graphics.translate(w/2-cx, h/2-cy)
    for _, tile in pairs(tiles) do
        render_tile(tile)
    end
    local mx, my = love.mouse.getPosition()
    local mcx, mcy = pos_to_tile(mx, my)
    if currently_moving == nil and valid_3x3(mcx, mcy) then
        render_tile_selection(mcx-1, mcy-1, mcx+1, mcy+1, 0, 0.5, 1)
    elseif currently_moving ~= nil then
        render_tile_selection(currently_moving[1]-1, currently_moving[2]-1, currently_moving[1]+1, currently_moving[2]+1, 0, 1, 0)
        if valid_destination(mcx, mcy) then
            render_tile_selection(mcx-1, mcy-1, mcx+1, mcy+1, 1, 0, 1)
        end
    end
end

function love.mousepressed(x, y, button)
    local tx, ty = pos_to_tile(x, y)
    if button == 1 then
        if not currently_moving and valid_3x3(tx, ty) then
            currently_moving = {tx, ty}
            for _, _, tile in neighborhood(tx, ty) do
                tile.pushoff = false
            end
        elseif currently_moving and valid_destination(tx, ty) then
            move_3x3(currently_moving[1], currently_moving[2], tx, ty)
            currently_moving = nil
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(2) then
        cx = cx - dx
        cy = cy - dy
    end
end

local function init()
    tiles = {}
    for x=-2, 2 do
        for y=-2, 2 do
            tiles[x.." "..y] = make_tile(x, y, (x+2)%5+(y+2)*5)
        end
    end
end
init()

local function scramble() -- proven always possible to solve by Milo Jacquet.
    tiles = {}
    local indices = {}
    for i=0, 24 do
        table.insert(indices, i)
    end
    for x=-2, 2 do
        for y=-2, 2 do
            local index = math.random(1, #indices)
            local n = indices[index]
            table.remove(indices, index)
            tiles[x.." "..y] = make_tile(x, y, n)
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        currently_moving = nil
        init()
    elseif key == "s" then
        currently_moving = nil
        scramble()
    end
end

function love.load()
    love.window.setTitle("Relocation")
end