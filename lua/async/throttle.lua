local timers = {}

return function(id, timeout, callback)
  if timers[id] then
    return
  end
  timers[id] = vim.loop.new_timer()
  timers[id]:start(timeout, 0, function()
    timers[id]:stop();
    timers[id]:close()
    timers[id] = nil
    callback()
  end)
end

