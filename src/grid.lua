local gfx = require("gfx")
local M = {}
M.__index = M

function M.new(selection_width)
    local new = {}
    setmetatable(new, M)
    new.tiles = {}
    new.sw = selection_width or 3
    new.history = {}
    new.future = {}
    return new
end

-- 1d index to 2d coordinates
function M.n_xy(n, w, h)
    return n%w, math.floor(n/h)
end
-- vice versa.
function M.xy_n(x, y, w)
    return x%w + y*w
end

function M:get(x, y)
    return self.tiles[x.." "..y]
end

-- "can one build off of this tile legally".
-- used during moves to disallow building a
-- tile on itself.
function M:pushoff(x, y)
    local tile = self:get(x, y)
    if not tile then return false end
    return tile.pushoff
end

function M:move(x, y, x2, y2)
    if self:pushoff(x2, y2) then error("overlap "..x2.." "..y2) end
    self.tiles[x2.." "..y2] = self.tiles[x.." "..y]
    self.tiles[x.." "..y] = nil
    self.tiles[x2.." "..y2].x = x2
    self.tiles[x2.." "..y2].y = y2
end

-- this is an iterator.
function M:neighborhood(x, y)
    local list = {}
    for i=0, self.sw^2-1 do
        local lx, ly = self.n_xy(i, self.sw, self.sw)
        local s = self:get(x+lx, y+ly)
        table.insert(list, {x=x+lx, y=y+ly, s=s})
    end
    local i = 0
    return function()
        i = i + 1
        if not list[i] then return nil end
        return list[i].x, list[i].y, list[i].s
    end
end

function M:move_block(x, y, tx, ty)
    local to_change = {}
    local to_erase = {}
    for ix, iy, tile in self:neighborhood(x, y) do
        local x2, y2 = ix+(tx-x), iy+(ty-y)
        to_change[x2.." "..y2] = tile
        if to_change[ix.." "..iy] == nil then
            to_erase[ix.." "..iy] = true
        end
        tile.x = x2
        tile.y = y2
        tile.pushoff = true
    end
    for k, _ in pairs(to_erase) do
        self.tiles[k] = nil
    end
    for k, v in pairs(to_change) do
        self.tiles[k] = v
    end
end

function M:valid_block(x, y) -- if it's filled.
    for x, y, s in self:neighborhood(x, y) do
        if not s then return false end
    end
    return true
end

-- checks if there's a tile adjacent to the sw x sw square
-- formed with pushoff == true.
function M:valid_destination(x, y)
    for _, _, s in self:neighborhood(x, y) do if s and s.pushoff then return false end end
    for i=0, self.sw-1 do
        if self:pushoff(x-1, y+i) then return true end
        if self:pushoff(x+self.sw, y+i) then return true end
        if self:pushoff(x+i, y-1) then return true end
        if self:pushoff(x+i, y+self.sw) then return true end
    end
    return false
end

function M:bounding_box()
    local left, right, top, bottom
    for _, v in pairs(self.tiles) do
        if not left or v.x < left then left = v.x end
        if not right or v.x > right then right = v.x end
        if not top or v.y < top then top = v.y end
        if not bottom or v.y > bottom then bottom = v.y end
    end
    return left, top, right, bottom
end

function M:enumerate_valid_moves()
    local res = {}
    local left, top, right, bottom = self:bounding_box()
    for x = left-self.sw, right+1 do
        for y = top-self.sw, bottom+1 do
            if self:valid_destination(x, y) then
                table.insert(res, {x, y})
            end
        end
    end
    return res
end

function M:tile_object(x, y, name, col)
    col = col or {1, 1, 1}
    return {x=x, y=y, text=name or "??", r = col[1], g = col[2], b = col[3], pushoff = true}
end

local tile_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
function M:init(w, h)
    for y=0, h-1 do
        for x=0, w-1 do
            local tilename = tile_alphabet:sub(x+1, x+1)..tostring(y+1)
            local cx, cy = x-math.floor(w/2), y-math.floor(h/2)
            local h, s, l = (x)/w, 1, 0.5 + (y+1)/(h*13/5)
            local r, g, b = gfx.HSL(h, s, l)
            self.tiles[cx.." "..cy] = self:tile_object(cx, cy, tilename, {r, g, b})
        end
    end
end

return M