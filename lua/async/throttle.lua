local timers = {}

return function(id, timeout, callback)
  if timers[id] then
    timers[id].callback = callback
    return
  end

  timers[id] = {
    timer = vim.loop.new_timer();
    callback = callback;
  }
  timers[id]:start(timeout, 0, function()
    timers[id].timer:stop();
    timers[id].timer:close()
    timers[id].timer = nil
    vim.defer_fn(timers[id].callback, 0)
  end)
end

