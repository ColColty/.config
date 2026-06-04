-- Keep long-lived nvim sessions from ratcheting up to tens of GB.
--
-- Two things cause the growth:
--   1. LuaJIT garbage piling up between collections (measured ~0.5 GB/idle-day).
--   2. glibc malloc never returning freed pages to the OS, so RSS sticks at its
--      high-water mark forever.
--
-- So: run the GC more eagerly, then every few minutes collect and hand the freed
-- heap back to the OS with malloc_trim (resolved straight from the running process).

collectgarbage("setpause", 110)
collectgarbage("setstepmul", 400)

local ffi = require("ffi")
pcall(ffi.cdef, "int malloc_trim(size_t pad);")

local timer = (vim.uv or vim.loop).new_timer()
timer:start(180000, 180000, vim.schedule_wrap(function()
  collectgarbage("collect")
  pcall(function() ffi.C.malloc_trim(0) end)
end))
