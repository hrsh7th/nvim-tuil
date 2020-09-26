local Class = require'lank.tuil.oop.class'

local FileSystem = Class()

function FileSystem.read_file(path, callback)
  vim.loop.fs_open(path, "r", 438, function(err, fd)
    assert(not err, err)
    vim.loop.fs_fstat(fd, function(err, stat)
      assert(not err, err)
      vim.loop.fs_read(fd, stat.size, 0, function(err, data)
        assert(not err, err)
        vim.loop.fs_close(fd, function(err)
          assert(not err, err)
          return callback(vim.split(data, '\n', true))
        end)
      end)
    end)
  end)
end

function FileSystem.scanfile(path, ignore_patterns, callback)
  vim.loop.fs_scandir(path, function(err, fs)
    if err then
      return -- ignore
    end

    while true do
      local name, type = vim.loop.fs_scandir_next(fs)
      if not name then
        callback(nil)
        break
      else
        local fullpath = path .. '/' .. name

        local ignore = false
        for _, pattern in ipairs(ignore_patterns) do
          if string.match(fullpath, pattern) then
            ignore = true
            break
          end
        end

        if not ignore then
          if type == 'file' then
            callback({ name = fullpath; type = type; })
          else
            FileSystem.scanfile(fullpath, ignore_patterns, callback)
          end
        end
      end
    end
  end)
end

return FileSystem
