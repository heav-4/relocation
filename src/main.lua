local grid = require("grid")
local gfx = require("gfx")

local world
local mode_name = "None"
local function init(s, w, h, msg)
    world = grid.new(s)
    world:init(w, h)
    mode_name = w.."x"..h.."+"..s
    gfx.text(msg.."\n".."Mode: "..mode_name)
    love.window.setTitle("Relocation ("..mode_name..")")
end

function love.draw()
    gfx.draw(world)
end

local function cancel_move()
    if world.currently_moving then
        for _, _, tile in world:neighborhood(world.currently_moving[1], world.currently_moving[2]) do
            tile.pushoff = true
        end
    end
    world.currently_moving = nil
    world.valid_moves = nil
end

function love.mousepressed(x, y, button)
    local tx, ty = gfx.pos_to_tile(x, y, -(world.sw-1)/2)
    if button == 1 then
        if not world.currently_moving and world:valid_block(tx, ty) then
            world.currently_moving = {tx, ty}
            for _, _, tile in world:neighborhood(tx, ty) do
                tile.pushoff = false
            end
            world.valid_moves = world:enumerate_valid_moves()
        elseif world.currently_moving and world:valid_destination(tx, ty) then
            if tx ~= world.currently_moving[1] or ty ~= world.currently_moving[2] then
                table.insert(world.history, {world.currently_moving[1], world.currently_moving[2], tx, ty})
            end
            world:move_block(world.currently_moving[1], world.currently_moving[2], tx, ty)
            world.currently_moving = nil
            world.valid_moves = nil
            world.future = {}
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(2) then
        gfx.cx = gfx.cx - dx
        gfx.cy = gfx.cy - dy
    end
end

local sw, w, h = 3, 5, 5
local function generic_switch(nsw, nw, nh, text)
    local min = math.min(nw, nh)
    local max = math.max(nw, nh)
    if nsw < 1 then
        gfx.text("You can't have a selection box of 0")
    elseif nsw > min then
        gfx.text("You can't have a selection box bigger than the smallest axis")
    elseif min < 1 then
        gfx.text("The board has to exist")
    elseif max > 52 then
        gfx.text("There aren't that many letters in the alphabet, sadly")
    else
        if nsw == 1 then text = "What an interesting nontrivial puzzle" end
        if nsw == max then text = "You're not going to be able to make any moves, you know" end
        if nsw == 1 and max == 1 then text = "Really now" end
        sw, w, h = nsw, nw, nh
        init(sw, w, h, text)
    end
end

local function undo()
    if #world.history == 0 then return gfx.text("Nothing to undo") end
    cancel_move()
    local move = world.history[#world.history]
    world:move_block(move[3], move[4], move[1], move[2])
    table.insert(world.future, move)
    table.remove(world.history, #world.history)
    gfx.text("Move undone")
end
local function redo()
    if #world.future == 0 then return gfx.text("Nothing to redo") end
    cancel_move()
    local move = world.future[#world.future]
    world:move_block(move[1], move[2], move[3], move[4])
    table.insert(world.history, move)
    table.remove(world.future, #world.future)
    gfx.text("Move redone")
end

function love.keypressed(key)
    if key == "escape" then
        init(sw, w, h, "Board reset")
    elseif key == "1" then
        sw, w, h = 3, 5, 5
        init(sw, w, h, "Switched to mode 1")
    elseif key == "2" then
        sw, w, h = 2, 5, 5
        init(sw, w, h, "Switched to mode 2")
    elseif key == "w" then
        if love.keyboard.isDown("lshift") then
            generic_switch(sw, w-1, h, "Decreased board width to "..w-1) 
        else
            generic_switch(sw, w+1, h, "Increased board width to "..w+1) 
        end
    elseif key == "h" then
        if love.keyboard.isDown("lshift") then
            generic_switch(sw, w, h-1, "Decreased board height to "..h-1) 
        else
            generic_switch(sw, w, h+1, "Increased board height to "..h+1) 
        end
    elseif key == "s" and not love.keyboard.isDown("lshift") then
        generic_switch(sw+1, w, h, "Selection box is now size "..sw+1)
    elseif key == "s" and love.keyboard.isDown("lshift") then
        generic_switch(sw-1, w, h, "Selection box is now size "..sw-1)
    elseif key == "z" and love.keyboard.isDown("lctrl") then
        if love.keyboard.isDown("lshift") then redo() else undo() end
    elseif key == "y" and love.keyboard.isDown("lctrl") then
        redo()
    end
end

init(sw, w, h, "Welcome to Relocation")