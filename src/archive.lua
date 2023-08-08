-- please ignore this file if you did not read about what it is for in overview of the codebase etc.txt. --

local function make_tile(x, y, n)
    local cx, cy = n_xy(n, 5, 5)
    local r, g, b = HSL((cx)/5, 1, 0.5 + (cy+1)/13)
    return {x=x, y=y, n=n, text=tile_name(n), pushoff = true, r=r, g=g, b=b}
end

