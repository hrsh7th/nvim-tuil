local Class = require'lank.tuil.oop.class'

local Emitter = Class()

function Emitter.init(self)
  self.listeners = {}
end

function Emitter.listener_count(self, name)
  return #(self.listeners[name] or {})
end

function Emitter.on(self, name, listener)
  self.listeners[name] = self.listeners[name] or {}

  table.insert(self.listeners[name], listener)
  return function()
    self:off(name, listener)
  end
end

function Emitter.once(self, name, listener)
  local callback = function(...)
    self:off(name, listener)
    listener(...)
  end
  self:on(name, callback)
end

function Emitter.off(self, name, ...)
  self.listeners[name] = self.listeners[name] or {}

  local listener = (select(1, ...))
  if listener ~= nil then
    self.listeners[name] = {}
  else
    for i, v in ipairs(self.listeners[name]) do
      if v == listener then
        table.remove(self.listeners[name], i)
        break
      end
    end
  end
end

function Emitter.emit(self, name, ...)
  self.listeners[name] = self.listeners[name] or {}

  for _, listener in ipairs(self.listeners[name .. ':before'] or {}) do
    listener(...)
  end

  for _, listener in ipairs(self.listeners[name]) do
    listener(...)
  end

  for _, listener in ipairs(self.listeners[name .. ':after'] or {}) do
    listener(...)
  end
end

return Emitter

