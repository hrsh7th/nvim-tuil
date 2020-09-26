local Class = require'tuil.oop.class'
local Emitter = require'tuil.event.emitter'

local Autocmd = Class(Emitter)

function Autocmd.init(self)
  Autocmd.super.init(self)
end

function Autocmd.on(self, name, listener)
  if self:listener_count(name) == 0 then
    vim.api.nvim_exec(([[
      augroup require.tuil.vim.autocmd.%s
        autocmd %s * lua require'tuil.vim.autocmd':emit('%s')
      augroup END
    ]]):format(name, name, name), false)
  end
  Autocmd.super.on(self, name, listener)
end

function Autocmd.off(self, name, ...)
  Autocmd.super.off(self, name, ...)

  if self:listener_count(name) == 0 then
    vim.api.nvim_exec(([[
      augroup require.tuil.vim.autocmd.%s
        autocmd!
      augroup END
    ]]):format(name), false)
  end
end

function Autocmd.emit(self, name)
  local event = {}
  if vim.tbl_contains({ 'WinClosed' }, name) then
    event.win = tonumber(vim.fn.expand('<afile>'), 10)
  else
    event.win = vim.api.nvim_get_current_win()
  end
  if vim.tbl_contains({ 'BufUnload', 'BufDelete', 'BufWipeout' }, name) then
    event.buf = tonumber(vim.fn.expand('<abuf>'), 10)
  else
    event.buf = vim.api.nvim_get_current_buf()
  end

  Autocmd.super.emit(self, name, event)
end

return Autocmd.new()

