local mt = {}
mt.__index = mt

function node(name, interactive)
    local new = {}
    setmetatable(new, mt)
    new.name = name
    new.dropdown = false
    new.elems = {}
    if interactive then new.interactive = true end
    return new
end

function mt:add(name, interactive)
    if not self.dropdown then
        self.dropdown = true
    end
    local new = node(name, interactive)
    new.parent = self
    table.insert(self.elems, new)
    return new
end

function mt:add_interactive(name)
    return self:add(name, true)
end

function mt:get_name()
    if type(self.name) == "string" then return self.name end
    return self.name("identify")
end

local settings = require("settings")

-- tree definition starts here, --

local root = node("Relocation")
local ps = root:add("Primary settings")
ps:add_interactive(function(context)
    if context == "activate" then settings.mute = not settings.mute end
    return "Sound: "..(settings.mute and "OFF" or "ON")
end)
ps:add_interactive(function(context)
    if context == "activate" then settings.grid = not settings.grid end
    return "Grid: "..(settings.grid and "ON" or "OFF")
end)
ps:add_interactive(function(context)
    if context == "activate" then settings.shapeonly = not settings.shapeonly end
    return "Shape only: "..(settings.shapeonly and "ON" or "OFF")
end)
root:add_interactive(function() return "Clicky sound" end)

-- and ends here. --

return root