local Class = require'lank.tuil.oop.class'
local Promise = require'lank.tuil.async.promise'
local Emitter = require'lank.tuil.event.emitter'
local Autocmd = require'lank.tuil.vim.autocmd'

local HORIZONTAL_COMMAND = {
  ['botright'] = 'botright new';
  ['topleft'] = 'topleft new';
}
local VERTICAL_COMMAND = {
  ['botright-v'] = 'vertical botright new';
  ['topleft-v'] = 'vertical topleft new';
}

local OPEN_WINDOWS = {}

Autocmd:on('WinClosed', function()
  local win = tonumber(vim.fn.expand('<afile>'), 10)
  if OPEN_WINDOWS[win] then
    OPEN_WINDOWS[win]:close()
    OPEN_WINDOWS[win]:emit('close', OPEN_WINDOWS[win])
    OPEN_WINDOWS[win] = nil
  end
end)

local Window = Class(Emitter)

function Window.resolve_percentage(value)
  if type(value) == 'string' then
    local s = string.match(value, '(%d+)%%')
    if not s then
      error('`style.width` format is invalid.')
    end
    return tonumber(s, 10) / 100
  end
  return value;
end

function Window.init(self, args)
  Window.super.init(self)
  self.win = nil
  self.buf = args.buf
  self.style = args.style or {}
  self.children = args.children or {}

  for _, child in ipairs(self.children) do
    if child.style.split then
      error('`children` must not use split.')
    end

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
  if self.style.width ~= nil then
    if type(self.style.width) == 'function' then
      width = math.floor(self.style.width(parent))
    elseif type(self.style.width) == 'string' then
      width = math.floor(parent.width * Window.resolve_percentage(self.style.width))
    else
      width = self.style.width
    end
  end

  local height = 1
  if self.style.height ~= nil then
    if type(self.style.height) == 'function' then
      height = math.floor(self.style.height(parent))
    elseif type(self.style.height) == 'string' then
      height = math.floor(parent.height * Window.resolve_percentage(self.style.height))
    else
      height = self.style.height
    end
  end

  if self.style.split then
    if HORIZONTAL_COMMAND[self.style.split] then
      vim.api.nvim_command(HORIZONTAL_COMMAND[self.style.split] .. (' | resize %s'):format(height))
    elseif VERTICAL_COMMAND[self.style.split] then
      vim.api.nvim_command(VERTICAL_COMMAND[self.style.split] .. (' | vertical resize %s'):format(width))
    end
    vim.api.nvim_set_current_buf(self.buf)
    self.win = vim.api.nvim_get_current_win()
  else
    local row = parent.row
    if self.style.row ~= nil then
      if type(self.style.row) == 'function' then
        row = math.floor(self.style.row(parent))
      elseif type(self.style.row) == 'string' then
        row = parent.row + math.floor(parent.row * Window.resolve_percentage(self.style.row))
      else
        row = math.floor(parent.row + self.style.row)
      end
    end

    local col = parent.col
    if self.style.col ~= nil then
      if type(self.style.col) == 'function' then
        col = math.floor(self.style.col(parent))
      elseif type(self.style.col) == 'string' then
        col = parent.col + math.floor(parent.col * Window.resolve_percentage(self.style.col))
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
      style = 'minimal';
    })
  end
  OPEN_WINDOWS[self.win] = self

  if self.style.highlight then
    vim.api.nvim_win_set_option(self.win, 'winhighlight', self.style.highlight)
  end

  return Promise.resolve():next(function()
    local rect = self:get_rect()
    local promise = Promise.resolve()
    for _, child in ipairs(self.children) do
      promise = promise:next(function()
        return child:open(rect)
      end)
    end
    return promise:next(function()
      self:emit('open', self)
    end)
  end)
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

function Window.find_by_buf(self, buf)
  if self.buf == buf then
    return self
  end
  for _, child in ipairs(self.children) do
    local w = child:find_by_buf(buf)
    if w then
      return w
    end
  end
  return nil
end

return Window

