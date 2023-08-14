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

return node