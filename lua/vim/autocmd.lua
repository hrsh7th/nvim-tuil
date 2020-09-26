local Class = require'lank.tuil.oop.class'
local Emitter = require'lank.tuil.event.emitter'

local Autocmd = Class(Emitter)

function Autocmd.init(self)
  Autocmd.super.init(self)
end

function Autocmd.on(self, name, listener)
  if self:listener_count(name) == 0 then
    vim.api.nvim_exec(([[
      augroup require.lank.tuil.vim.autocmd.%s
        autocmd %s * lua require'lank.tuil.vim.autocmd':emit('%s')
      augroup END
    ]]):format(name, name, name), false)
  end
  Autocmd.super.on(self, name, listener)
end

function Autocmd.off(self, name, ...)
  Autocmd.super.off(self, name, ...)

  if self:listener_count(name) == 0 then
    vim.api.nvim_exec(([[
      augroup require.lank.tuil.vim.autocmd.%s
        autocmd!
      augroup END
    ]]):format(name), false)
  end
end

return Autocmd.new()

