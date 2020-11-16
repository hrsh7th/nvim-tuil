local Class = require'tuil.oop.class'
local Promise = require'tuil.async.promise'
local Emitter = require'tuil.event.emitter'
local Autocmd = require'tuil.vim.autocmd'
local bind = require'tuil.functional.bind'

local Window = Class(Emitter)

function Window.init(self, factory)
  Window.super.init(self)

  self.factory = factory
  self.elements = {}
  self._on_close = bind(self._on_close, self)
end

function Window.get_win_by_buf(self, buffer)
  for window, element in pairs(self.elements) do
    if element.buffer == buffer and vim.api.nvim_win_is_valid(window) then
      return window
    end
  end
  return nil
end

function Window.get_rect_by_buf(self, buffer)
  for window, element in pairs(self.elements) do
    if element.buffer == buffer and vim.api.nvim_win_is_valid(window) then
      return {
        width = element.style.width;
        height = element.style.height;
        row = element.style.row;
        col = element.style.col;
      }
    end
  end
  return nil
end

function Window.shown(self)
  local count = 0
  for window in pairs(self.elements) do
    count = count + 1
    if not vim.api.nvim_win_is_valid(window) then
      return false
    end
  end
  return count > 0
end

-- open or update elements.
function Window.open(self, ...)
  local viewport = {
    row = 0;
    col = 0;
    width = vim.o.columns;
    height = vim.o.lines;
  };
  local props = (select(1, ...)) or {}

  local shown = self:shown()
  return self:_create(viewport, props, self.factory):next(function(next_elements)
    local prev_elements = self.elements
    self.elements = next_elements
    for prev_window in pairs(prev_elements) do
      if not next_elements[prev_window] then
        vim.api.nvim_win_close(prev_window, true)
      end
    end

    Autocmd:on('WinClosed', self._on_close)
    if not shown then
      self:emit('open')
    end
  end)
end

-- close all elements.
function Window.close(self)
  for window in pairs(self.elements) do
    if vim.api.nvim_win_is_valid(window) then
      vim.api.nvim_win_close(window, true)
    end
  end
  self.elements = {}

  Autocmd:off('WinClosed', self._on_close)
  self:emit('close')
end

-- create concrete elements recursively.
function Window._create(self, viewport, props, factory)
  local element = factory(viewport, props)
  if not element then
    return Promise.resolve({})
  end
  element.style.row = (element.style.row or 0) + viewport.row
  element.style.col = (element.style.col or 0) + viewport.col

  local elements = {}
  if element.buffer then
    if element.style.split then
      assert(self.factory == factory, 'style.split allowed to the root element only.')
    end
    elements[self:_render(element)] = element
  end

  local promise = Promise.resolve()

  local child_viewport = {
    width = element.style.width or viewport.width;
    height = element.style.height or viewport.height;
    row = element.style.row or 0;
    col = element.style.col or 0;
  }
  for _, child_factory in ipairs(element.children or {}) do
    promise = promise:next(function()
      return self:_create(child_viewport, props, child_factory):next(function(child_elements)
        for child_window, child_element in pairs(child_elements) do
          elements[child_window] = child_element
        end
        return elements
      end):next(function()
      end)
    end)
  end
  return promise:next(function()
    return elements
  end)
end

function Window._render(self, element)
  local window = self:get_win_by_buf(element.buffer)

  -- update
  if window then
    local current_element = self.elements[window]
    if element.style.split then
      if element.style.split == 'top' or element.style.split == 'bottom' then
        if current_element.style.height ~= element.style.height then
          vim.api.nvim_win_set_height(window, math.floor(element.style.height))
        end
      else
        if current_element.style.width ~= element.style.width then
          vim.api.nvim_win_set_width(window, math.floor(element.style.width))
        end
      end
      local pos = vim.api.nvim_win_get_position(window)
      element.width = vim.api.nvim_win_get_width(window)
      element.height = vim.api.nvim_win_get_height(window)
      element.style.row = pos[1]
      element.style.col = pos[2]
    else
      local changed = false
      changed = changed or current_element.style.width ~= element.style.width
      changed = changed or current_element.style.height ~= element.style.height
      changed = changed or current_element.style.row ~= element.style.row
      changed = changed or current_element.style.col ~= element.style.col
      if changed then
        vim.api.nvim_win_set_config(window, {
          relative = 'editor';
          width = math.floor(element.style.width);
          height = math.floor(element.style.height);
          row = math.floor(element.style.row);
          col = math.floor(element.style.col);
          style = 'minimal';
        })
      end
    end

  -- create
  else
    if element.style.split then
      if element.style.split == 'top' then
        vim.api.nvim_command('topleft new')
        window = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_height(window, math.floor(element.style.height))
      elseif element.style.split == 'bottom' then
        vim.api.nvim_command('botright new')
        window = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_height(window, math.floor(element.style.height))
      elseif element.style.split == 'left' then
        vim.api.nvim_command('vertical topleft new')
        window = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_width(window, math.floor(element.style.width))
      elseif element.style.split == 'right' then
        vim.api.nvim_command('vertical botright new')
        window = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_width(window, math.floor(element.style.width))
      end
      local pos = vim.api.nvim_win_get_position(window)
      element.width = vim.api.nvim_win_get_width(window)
      element.height = vim.api.nvim_win_get_height(window)
      element.style.row = pos[1]
      element.style.col = pos[2]
      vim.api.nvim_win_set_buf(window, element.buffer)
    else
      window = vim.api.nvim_open_win(element.buffer, false, {
        relative = 'editor';
        width = math.floor(element.style.width);
        height = math.floor(element.style.height);
        row = math.floor(element.style.row);
        col = math.floor(element.style.col);
        style = 'minimal';
      })
    end
  end

  if element.style.highlight then
    vim.api.nvim_win_set_option(window, 'winhighlight', element.style.highlight)
  end
  return window
end

function Window._on_close(self)
  local window = tonumber(vim.fn.expand('<afile>'), 10)
  if self.elements[window] then
    self:close()
  end
end

return Window

