local Class = require'tuil.oop.class'
local Emitter = require'tuil.event.emitter'
local Autocmd = require'tuil.vim.autocmd'

local OPEN_WINDOWS = {}

Autocmd:on('WinClosed', function(event)
  if OPEN_WINDOWS[event.win] then
    OPEN_WINDOWS[event.win]:close()
    OPEN_WINDOWS[event.win]:emit('close', OPEN_WINDOWS[event.win])
    OPEN_WINDOWS[event.win] = nil
  end
end)

local Window = Class(Emitter)

function Window.init(self, args)
  Window.super.init(self)
  self.win = nil
  self.buf = args.buf
  self.style = args.style or {}
  self.children = args.children or {}

  for _, child in ipairs(self.children) do
    child:on('close', function()
      self:close()
    end)
  end
end

function Window.shown(self)
  return self.win and vim.api.nvim_win_is_valid(self.win)
end

function Window.open(self, ...)
  if self:shown() then
    return
  end

  local parent = (select(1, ...)) or {
    row = 1;
    col = 1;
    width = vim.o.columns;
    height = vim.o.lines;
  }

  local width = parent.width
  if self.style.width then
    if 0 <= self.style.width and self.style.width <= 1 then
      width = math.floor(parent.width * self.style.width)
    elseif self.style.width < 0 then
      width = math.floor(parent.width + self.style.width)
    else
      width = math.floor(self.style.width)
    end
  end

  local height = parent.height
  if self.style.height then
    if 0 <= self.style.height and self.style.height <= 1 then
      height = math.floor(parent.height * self.style.height)
    elseif self.style.height < 0 then
      height = math.floor(parent.height + self.style.height)
    else
      height = math.floor(self.style.height)
    end
  end

  local row = parent.row
  if self.style.row then
    if 0 <= self.style.row and self.style.row <= 1 then
      row = parent.row + math.floor(parent.height * self.style.row)
    else
      row = math.floor(parent.row + self.style.row)
    end
  end

  local col = parent.col
  if self.style.col then
    if 0 <= self.style.col and self.style.col <= 1 then
      col = parent.col + math.floor(parent.width * self.style.col)
    else
      col = math.floor(parent.col + self.style.col)
    end
  end

  self.win = vim.api.nvim_open_win(self.buf, true, {
    relative = 'editor';
    width = width;
    height = height;
    row = row;
    col = col;
  })
  OPEN_WINDOWS[self.win] = self

  if self.style.highlight then
    vim.api.nvim_win_set_option(self.win, 'winhighlight', self.style.highlight)
  end

  vim.defer_fn(function()
    self:emit('open', self)

    local rect = self:get_rect()
    print(vim.inspect(rect))
    for _, child in ipairs(self.children) do
      child:open(rect)
    end
  end, 0)
end

function Window:close()
  for _, child in ipairs(self.children) do
    child:close()
  end

  if self:shown() then
    vim.api.nvim_win_close(self.win, true)
    self:emit('close', self)
  end
end

function Window.get_rect(self)
  if not self:shown() then
    return nil
  end

  local pos = vim.api.nvim_win_get_position(self.win)
  return {
    row = pos[1];
    col = pos[2];
    width = vim.api.nvim_win_get_width(self.win);
    height = vim.api.nvim_win_get_height(self.win);
  }
end

return Window

