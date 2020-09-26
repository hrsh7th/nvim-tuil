return function(...)
  local Parent = (select(1, ...))

  local Class = Parent and setmetatable({}, { __index = Parent }) or {}

  Class.super = Parent

  -- factory
  Class.new = function(...)
    local this = setmetatable({}, { __index = Class })
    Class.init(this, ...)
    return this
  end

  -- default constructor
  function Class.init(self, ...)
    if Class.super then
      Class.super.init(self, ...)
    end
  end

  return Class
end
