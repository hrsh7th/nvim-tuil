local tuil = {}

function tuil.bind(func, ...)
  local binds = ...
  return function(...)
    func(binds, ...)
  end
end

return tuil
