-- fio.lua (internal file)

local fio = require('fio')
local ffi = require('ffi')
local buffer = require('buffer')
local signal = require('signal')
local errno = require('errno')

ffi.cdef[[
    int umask(int mask);
    char *dirname(char *path);
    int chdir(const char *path);
]]

local const_char_ptr_t = ffi.typeof('const char *')

local internal = fio.internal
fio.internal = nil

fio.STDIN = 0
fio.STDOUT = 1
fio.STDERR = 2
fio.PIPE = -2
fio.DEVNULL = -3
fio.TIMEOUT_INFINITY = 500 * 365 * 86400


local function sprintf(fmt, ...)
    if select('#', ...) == 0 then
        return fmt
    end
    return string.format(fmt, ...)
end

local fio_methods = {}

-- read() -> str
-- read(buf) -> len
-- read(size) -> str
-- read(buf, size) -> len
fio_methods.read = function(self, buf, size)
    local tmpbuf
    if (not ffi.istype(const_char_ptr_t, buf) and buf == nil) or
        (ffi.istype(const_char_ptr_t, buf) and size == nil) then
        local st, err = self:stat()
        if st == nil then
            return nil, err
        end
        size = st.size
    end
    if not ffi.istype(const_char_ptr_t, buf) then
        size = buf or size
        tmpbuf = buffer.ibuf()
        buf = tmpbuf:reserve(size)
    end
    local res, err = internal.read(self.fh, buf, size)
    if res == nil then
        if tmpbuf ~= nil then
            tmpbuf:recycle()
        end
        return nil, err
    end
    if tmpbuf ~= nil then
        tmpbuf:alloc(res)
        res = ffi.string(tmpbuf.rpos, tmpbuf:size())
        tmpbuf:recycle()
    end
    return res
end

-- write(str)
-- write(buf, len)
fio_methods.write = function(self, data, len)
    if not ffi.istype(const_char_ptr_t, data) then
        data = tostring(data)
        len = #data
    end
    local res, err = internal.write(self.fh, data, len)
    if err ~= nil then
        return false, err
    end
    return res >= 0
end

-- pwrite(str, offset)
-- pwrite(buf, len, offset)
fio_methods.pwrite = function(self, data, len, offset)
    if not ffi.istype(const_char_ptr_t, data) then
        data = tostring(data)
        offset = len
        len = #data
    end
    local res, err = internal.pwrite(self.fh, data, len, offset)
    if err ~= nil then
        return false, err
    end
    return res >= 0
end

-- pread(size, offset) -> str
-- pread(buf, size, offset) -> len
fio_methods.pread = function(self, buf, size, offset)
    local tmpbuf
    if not ffi.istype(const_char_ptr_t, buf) then
        offset = size
        size = buf
        tmpbuf = buffer.IBUF_SHARED
        tmpbuf:reset()
        buf = tmpbuf:reserve(size)
    end
    local res, err = internal.pread(self.fh, buf, size, offset)
    if res == nil then
        if tmpbuf ~= nil then
            tmpbuf:recycle()
        end
        return nil, err
    end
    if tmpbuf ~= nil then
        tmpbuf:alloc(res)
        res = ffi.string(tmpbuf.rpos, tmpbuf:size())
        tmpbuf:recycle()
    end
    return res
end

fio_methods.truncate = function(self, length)
    if length == nil then
        length = 0
    end
    return internal.ftruncate(self.fh, length)
end

fio_methods.seek = function(self, offset, whence)
    if whence == nil then
        whence = 'SEEK_SET'
    end
    if type(whence) == 'string' then
        if fio.c.seek[whence] == nil then
            error(sprintf("fio.seek(): unknown whence: %s", whence))
        end
        whence = fio.c.seek[whence]
    else
        whence = tonumber(whence)
    end

    local res = internal.lseek(self.fh, tonumber(offset), whence)
    return tonumber(res)
end

fio_methods.close = function(self)
    local res, err = internal.close(self.fh)
    self.fh = -1
    if err ~= nil then
        return false, err
    end
    return res
end

fio_methods.fsync = function(self)
    return internal.fsync(self.fh)
end

fio_methods.fdatasync = function(self)
    return internal.fdatasync(self.fh)
end

fio_methods.stat = function(self)
    return internal.fstat(self.fh)
end

local fio_mt = { __index = fio_methods }

fio.open = function(path, flags, mode)
    local iflag = 0
    local imode = 0
    if type(path) ~= 'string' then
        error("Usage: fio.open(path[, flags[, mode]])")
    end
    if type(flags) ~= 'table' then
        flags = { flags }
    end
    if type(mode) ~= 'table' then
        mode = { mode or (bit.band(0x1FF, fio.umask())) }
    end


    for _, flag in pairs(flags) do
        if type(flag) == 'number' then
            iflag = bit.bor(iflag, flag)
        else
            if fio.c.flag[ flag ] == nil then
                error(sprintf("fio.open(): unknown flag: %s", flag))
            end
            iflag = bit.bor(iflag, fio.c.flag[ flag ])
        end
    end

    for _, m in pairs(mode) do
        if type(m) == 'string' then
            if fio.c.mode[m] == nil then
                error(sprintf("fio.open(): unknown mode: %s", m))
            end
            imode = bit.bor(imode, fio.c.mode[m])
        else
            imode = bit.bor(imode, tonumber(m))
        end
    end

    local fh, err = internal.open(tostring(path), iflag, imode)
    if err ~= nil then
        return nil, err
    end

    fh = { fh = fh }
    setmetatable(fh, fio_mt)
    return fh
end

local popen_methods = {}

-- read stdout & stderr of the process started by fio.popen
-- Usage:
-- read(size) -> str, source, err
-- read(buf, size) -> length, source, err
-- read(size, timeout) -> str, source, err
-- read(buf, size, timeout) -> length, source, err
--
-- timeout - number of seconds to wait (optional)
-- source contains id of the stream, fio.STDOUT or fio.STDERR
-- err - error message if method has failed or nil on success
popen_methods.read = function(self, buf, size, timeout)
    if self.fh == nil then
        return nil, nil, 'Invalid object'
    end

    if type(buf) == 'table' then
        timeout = buf.timeout or timeout
        size = buf.size or size
        buf = buf.buf
    end

    local tmpbuf

    if ffi.istype(const_char_ptr_t, buf) then
        -- ext. buffer is specified
        if type(size) ~= 'number' then
            error('fio.popen.read: invalid size argument')
        end
        timeout = timeout or fio.TIMEOUT_INFINITY
    elseif type(buf) == 'number' then
        -- use temp. buffer
        timeout = size or fio.TIMEOUT_INFINITY
        size = buf

        tmpbuf = buffer.ibuf()
        buf = tmpbuf:reserve(size)
    elseif buf == nil and type(size) == 'number' then
        tmpbuf = buffer.ibuf()
        buf = tmpbuf:reserve(size)
    else
        error("fio.popen.read: invalid arguments")
    end

    local res, output_no, err = internal.popen_read(self.fh, buf, size, timeout)
    if res == nil then
        if tmpbuf ~= nil then
            tmpbuf:recycle()
        end
        return nil, nil, err
    end

    if tmpbuf ~= nil then
        tmpbuf:alloc(res)
        res = ffi.string(tmpbuf.rpos, tmpbuf:size())
        tmpbuf:recycle()
    end
    return res, output_no
end

-- write(str)
-- write(buf, len)
popen_methods.write = function(self, data, size)
    local timeout = fio.TIMEOUT_INFINITY
    if type(data) == 'table' then
        timeout = data.timeout or timeout
        size = data.size or size
        data = data.buf
    end

    if type(data) == 'string' then
        if size == nil then
            size = string.len(data)
        end
    elseif not ffi.istype(const_char_ptr_t, data) then
        data = tostring(data)
        size = #data
    end

    return internal.popen_write(self.fh, data,
            tonumber(size), tonumber(timeout))
end

popen_methods.status = function(self)
    if self.fh ~= nil then
        return internal.popen_get_status(self.fh)
    else
        return self.exit_code
    end
end

popen_methods.stdin = function (self)
    if self.fh == nil then
        return nil, 'Invalid object'
    end

    return internal.popen_get_std_file_handle(self.fh, fio.STDIN)
end

popen_methods.stdout = function (self)
    if self.fh == nil then
        return nil, 'Invalid object'
    end

    return internal.popen_get_std_file_handle(self.fh, fio.STDOUT)
end

popen_methods.stderr = function (self)
    if self.fh == nil then
        return nil, 'Invalid object'
    end

    return internal.popen_get_std_file_handle(self.fh, fio.STDERR)
end

popen_methods.kill = function(self, sig)
    if self.fh == nil then
        return false, errno.strerror(errno.ESRCH)
    end

    if sig == nil then
        sig = signal.SIGTERM
    end
    sig = tonumber(sig)

    return internal.popen_kill(self.fh, sig)
end

popen_methods.wait = function(self, timeout)
    if self.fh == nil then
        return false, 'Invalid object'
    end

    if timeout == nil then
        timeout = fio.TIMEOUT_INFINITY
    else
        timeout = tonumber(timeout)
    end

    return internal.popen_wait(self.fh, timeout)
end

popen_methods.shutdown = function(self)
    if self.fh == nil then
        return false, 'Invalid object'
    end

    local c = internal.popen_get_status(self.fh)
    local rc, err = internal.popen_shutdown(self.fh)
    if rc ~= nil then
        self.exit_code = c
        self.fh = nil
        return true
    else
        return false,err
    end
end

popen_methods.close = function(self, fd)
    if self.fh == nil then
        return false, 'Invalid object'
    end

    if fd == nil then
        fd = -1
    end

    return internal.popen_close(self.fh, tonumber(fd))
end

local popen_mt = { __index = popen_methods }

fio.popen = function(args, opts)
    local env = opts and opts.env
    local hstdin = opts and opts.stdin
    local hstdout = opts and opts.stdout
    local hstderr = opts and opts.stderr

    if type(hstdin) == 'table' then
        hstdin = hstdin.fh
    end
    if type(hstdout) == 'table' then
        hstdout = hstdout.fh
    end
    if type(hstderr) == 'table' then
        hstderr = hstderr.fh
    end

    if args == nil or
       type(args) ~= 'table' or
       table.getn(args) < 1 then
        error('Usage: fio.popen({args}[, {opts}])')
    end

    local fh,err = internal.popen(args, env, hstdin, hstdout, hstderr)
    if err ~= nil then
        return nil, err
    end

    local pobj = {fh = fh}
    setmetatable(pobj, popen_mt)
    return pobj
end

fio.pathjoin = function(...)
    local i, path = 1, nil

    local len = select('#', ...)
    while i <= len do
        local sp = select(i, ...)
        if sp == nil then
            error("fio.pathjoin(): undefined path part "..i)
        end

        sp = tostring(sp)
        if sp ~= '' then
            path = sp
            break
        else
            i = i + 1
        end
    end

    if path == nil then
        return '.'
    end

    i = i + 1
    while i <= len do
        local sp = select(i, ...)
        if sp == nil then
            error("fio.pathjoin(): undefined path part "..i)
        end

        sp = tostring(sp)
        if sp ~= '' then
            path = path .. '/' .. sp
        end

        i = i + 1
    end

    path = path:gsub('/+', '/')
    if path ~= '/' then
        path = path:gsub('/$', '')
    end

    return path
end

fio.basename = function(path, suffix)
    if type(path) ~= 'string' then
        error("Usage: fio.basename(path[, suffix])")
    end

    path = tostring(path)
    path = string.gsub(path, '.*/', '')

    if suffix ~= nil then
        suffix = tostring(suffix)
        if #suffix > 0 then
            suffix = string.gsub(suffix, '(.)', '[%1]')
            path = string.gsub(path, suffix, '')
        end
    end

    return path
end

fio.dirname = function(path)
    if type(path) ~= 'string' then
        error("Usage: fio.dirname(path)")
    end
    -- Can't just cast path to char * - on Linux dirname modifies
    -- its argument.
    local bsize = #path + 1
    local cpath = buffer.static_alloc('char', bsize)
    ffi.copy(cpath, ffi.cast('const char *', path), bsize)
    return ffi.string(ffi.C.dirname(cpath))
end

fio.umask = function(umask)

    if umask == nil then
        local old = ffi.C.umask(0)
        ffi.C.umask(old)
        return old
    end

    umask = tonumber(umask)

    return ffi.C.umask(tonumber(umask))

end

fio.abspath = function(path)
    -- following established conventions of fio module:
    -- letting nil through and converting path to string
    if path == nil then
        error("Usage: fio.abspath(path)")
    end
    path = path
    local joined_path = ''
    local path_tab = {}
    if string.sub(path, 1, 1) == '/' then
        joined_path = path
    else
        joined_path = fio.pathjoin(fio.cwd(), path)
    end
    for sp in string.gmatch(joined_path, '[^/]+') do
        if sp == '..' then
            table.remove(path_tab)
        elseif sp ~= '.' then
            table.insert(path_tab, sp)
        end
    end
    return '/' .. table.concat(path_tab, '/')
end

fio.chdir = function(path)
    if type(path)~='string' then
        error("Usage: fio.chdir(path)")
    end
    return ffi.C.chdir(path) == 0
end

fio.listdir = function(path)
    if type(path) ~= 'string' then
        error("Usage: fio.listdir(path)")
    end
    local str, err = internal.listdir(path)
    if err ~= nil then
        return nil, string.format("can't listdir %s: %s", path, err)
    end
    local t = {}
    if str == "" then
        return t
    end
    local names = string.split(str, "\n")
    for i, name in ipairs(names) do
        table.insert(t, name)
    end
    return t
end

fio.mktree = function(path, mode)
    if type(path) ~= "string" then
        error("Usage: fio.mktree(path[, mode])")
    end
    path = fio.abspath(path)

    local path = string.gsub(path, '^/', '')
    local dirs = string.split(path, "/")

    local current_dir = "/"
    for i, dir in ipairs(dirs) do
        current_dir = fio.pathjoin(current_dir, dir)
        if not fio.stat(current_dir) then
            local st, err = fio.mkdir(current_dir, mode)
            if err ~= nil  then
                return false, string.format("Error creating directory %s: %s",
                    current_dir, tostring(err))
            end
        end
    end
    return true
end

fio.rmtree = function(path)
    if type(path) ~= 'string' then
        error("Usage: fio.rmtree(path)")
    end
    local status, err
    path = fio.abspath(path)
    local ls, err = fio.listdir(path)
    if err ~= nil then
        return nil, err
    end
    for i, f in ipairs(ls) do
        local tmppath = fio.pathjoin(path, f)
        local st = fio.lstat(tmppath)
        if st then
            if st:is_dir() then
                st, err = fio.rmtree(tmppath)
            else
                st, err = fio.unlink(tmppath)
            end
            if err ~= nil  then
                return nil, err
            end
        end
    end
    status, err = fio.rmdir(path)
    if err ~= nil then
        return false, string.format("failed to remove %s: %s", path, err)
    end
    return true
end

fio.copyfile = function(from, to)
    if type(from) ~= 'string' or type(to) ~= 'string' then
        error('Usage: fio.copyfile(from, to)')
    end
    local st = fio.stat(to)
    if st and st:is_dir() then
        to = fio.pathjoin(to, fio.basename(from))
    end
    local _, err = internal.copyfile(from, to)
    if err ~= nil then
        return false, string.format("failed to copy %s to %s: %s", from, to, err)
    end
    return true
end

fio.copytree = function(from, to)
    if type(from) ~= 'string' or type(to) ~= 'string' then
        error('Usage: fio.copytree(from, to)')
    end
    local status, reason
    local st = fio.stat(from)
    if not st then
        return false, string.format("Directory %s does not exist", from)
    end
    if not st:is_dir() then
        return false, errno.strerror(errno.ENOTDIR)
    end
    local ls, err = fio.listdir(from)
    if err ~= nil then
        return false, err
    end

    -- create tree of destination
    status, reason = fio.mktree(to)
    if reason ~= nil then
        return false, reason
    end
    for i, f in ipairs(ls) do
        local ffrom = fio.pathjoin(from, f)
        local fto = fio.pathjoin(to, f)
        local st = fio.lstat(ffrom)
        if st and st:is_dir() then
            status, reason = fio.copytree(ffrom, fto)
            if reason ~= nil then
                return false, reason
            end
        end
        if st:is_reg() then
            status, reason = fio.copyfile(ffrom, fto)
            if reason ~= nil then
                return false, reason
            end
        end
        if st:is_link() then
            local link_to, reason = fio.readlink(ffrom)
            if reason ~= nil then
                return false, reason
            end
            status, reason = fio.symlink(link_to, fto)
            if reason ~= nil then
                return false, "can't create symlink in place of existing file "..fto
            end
        end
    end
    return true
end

fio.path = {}
fio.path.is_file = function(filename)
    local fs = fio.stat(filename)
    return fs ~= nil and fs:is_reg() or false
end

fio.path.is_link = function(filename)
    local fs = fio.lstat(filename)
    return fs ~= nil and fs:is_link() or false
end

fio.path.is_dir = function(filename)
    local fs = fio.stat(filename)
    return fs ~= nil and fs:is_dir() or false
end

fio.path.exists = function(filename)
    return fio.stat(filename) ~= nil
end

fio.path.lexists = function(filename)
    return fio.lstat(filename) ~= nil
end

return fio
