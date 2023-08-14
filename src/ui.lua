local M = {}
local ut = require("ui_tree_structure")
local sfx = require("sfx")
M.is_open = false
M.blocking_inputs = false
M.tree = ut
M.selected = 1

local sidepanel_deployment = 0
local target_sidepanel_deployment = 0
local font = love.graphics.newFont(15)

function M.open()
    M.is_open = true
    M.blocking_inputs = true
    M.selected = 1
    sidepanel_deployment = 0
    target_sidepanel_deployment = 1
end

function M.close()
    M.blocking_inputs = false
    target_sidepanel_deployment = 0
end

local function sidepanel_width()
    local w, h = love.graphics.getDimensions()
    return math.max(300, w/8)
end

local function text_x()
    local sp_w = sidepanel_width()
    return math.max(5, sp_w/20)
end
local function text_w()
    return sidepanel_width() - 2*text_x()
end
local function text_h()
    return font:getHeight()
end
local function text_y(n)
    return text_x() + n*text_h()
end

function M.fit_text(text)
    local tw = text_w()
    local replacements = 0
    while font:getWidth(text) > tw do
        text = text:sub(1, #text-(replacements==0 and 1 or 4)) .. "..."
        replacements = replacements + 1
    end
    return text
end

local function draw_text(text, n, dropdown)
    local tx = text_x()
    local ty = text_y(n)
    love.graphics.setColor(1,dropdown and 0.5 or 1,1)
    love.graphics.print(text, font, tx, ty)
end

local function draw_sidepanel()
    local w, h = love.graphics.getDimensions()
    local sp_w = sidepanel_width()
    love.graphics.setColor(0.1, 0.1, 0.3, 1)
    love.graphics.rectangle("fill", 0, 0, sp_w, h)
    love.graphics.setColor(0.1, 0.1, 0.5, 1)
    love.graphics.rectangle("fill", 0, 0, sp_w, text_x()*2 + 1*text_h())
    love.graphics.setColor(0.2, 0.2, 0.4, 1)
    love.graphics.rectangle("fill", 0, text_y(M.selected+1), sp_w, text_h())
    draw_text(M.tree.root.name, 0)
    if M.tree.root.elems then for i=1, #M.tree.root.elems do
        local elem = M.tree.root.elems[i]
        draw_text(elem:get_name(), i+1, elem.dropdown)
    end end
end

function M.render()
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.5 * sidepanel_deployment)
    love.graphics.rectangle("fill", 0, 0, w, h)
    if target_sidepanel_deployment == 0 and sidepanel_deployment < 0.01 then M.is_open = false end
    sidepanel_deployment = sidepanel_deployment + (target_sidepanel_deployment - sidepanel_deployment) / 3
    love.graphics.push()
    local sp_w = sidepanel_width()
    love.graphics.translate(-(1-sidepanel_deployment)*sp_w, 0)
    draw_sidepanel()
    love.graphics.pop()
end

local function select(n)
    if M.tree.root.elems and #M.tree.root.elems > 0 then
        n = ((n-1)%#M.tree.root.elems)+1
        M.selected = n
    end
end

function M.enter(node)
    M.tree.root.selected = M.selected
    if not node.selected then
        M.selected = 1
    else
        M.selected = node.selected
    end
    M.tree.root = node
end

function M.keypressed(key)
    if key == "left" then
        sfx.play("undo", 0.5)
        if not M.tree.root.parent then
            M.close()
        else
            M.enter(M.tree.root.parent)
        end
    elseif key == "right" and M.tree.root.elems[M.selected] then
        if M.tree.root.elems[M.selected].dropdown then
            sfx.play("place")
            M.enter(M.tree.root.elems[M.selected])
        elseif M.tree.root.elems[M.selected].interactive then
            M.tree.root.elems[M.selected].name("activate")
            sfx.play("swap")
        end
    elseif key == "up" then
        select(M.selected-1)
        sfx.play("select")
    elseif key == "down" then
        select(M.selected+1)
        sfx.play("select")
    end
end

return M