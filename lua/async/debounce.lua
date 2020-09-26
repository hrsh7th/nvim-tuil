local timers = {}

return function(id, timeout, callback)
  if timers[id] then
    timers[id]:stop()
    timers[id]:close()
  end
  timers[id] = vim.loop.new_timer()
  timers[id]:start(timeout, 0, callback)
end
