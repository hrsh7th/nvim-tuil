return function(func, ...)
  local binds = ...
  return function(...)
    func(binds, ...)
  end
end

