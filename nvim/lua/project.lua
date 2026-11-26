-- nvim/lua/project.lua
local M = { jobs = {}, selections = {} }
local startup_dir = vim.fn.getcwd()
local function notify(message, level) vim.notify(message, level or vim.log.levels.INFO) end
function M.root(buf)
  buf = buf or 0
  local name = vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) or ""
  local start = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
  return vim.fs.root(start, { { ".git", ".clangd" } }) or startup_dir
end
local function is_absolute(path)
  return path:sub(1, 1) == "/" or path:match("^%a:[/\\]") ~= nil or path:sub(1, 2) == "\\\\"
end
local function split_args(text)
  local args, current, quote = {}, {}, nil
  for char in text:gmatch(".") do
    if quote then
      if char == quote then quote = nil else current[#current + 1] = char end
    elseif char == '"' or char == "'" then
      quote = char
    elseif char:match("%s") then
      if #current > 0 then args[#args + 1] = table.concat(current); current = {} end
    else
      current[#current + 1] = char
    end
  end
  if #current > 0 then args[#args + 1] = table.concat(current) end
  return args
end
function M.build_type()
  return vim.g.cxx_build_type or "Debug"
end
function M.build_dir(root)
  local dir = vim.g.cxx_build_dir or "build"
  if is_absolute(dir) then return dir end
  return vim.fs.joinpath(root or M.root(), dir)
end
local function read_json(path)
  local ok, data = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(path), "\n")) end)
  return ok and data or nil
end
local function configured_build_type(dir)
  local path = dir .. "/CMakeCache.txt"
  if vim.fn.filereadable(path) == 0 then return nil end
  for _, line in ipairs(vim.fn.readfile(path)) do
    local value = line:match("^CMAKE_BUILD_TYPE:STRING=(.*)$")
    if value then return value ~= "" and value or nil end
  end
  return nil
end
function M.targets(root)
  local dir = M.build_dir(root)
  local replies = vim.fn.glob(dir .. "/.cmake/api/v1/reply/index-*.json", false, true)
  table.sort(replies)
  local index = replies[#replies] and read_json(replies[#replies])
  local ref = index and index.reply and index.reply["codemodel-v2"]
  local model = ref and ref.jsonFile and read_json(dir .. "/.cmake/api/v1/reply/" .. ref.jsonFile)
  if not model then return {} end
  local config
  for _, item in ipairs(model.configurations or {}) do
    if item.name == M.build_type() then config = item; break end
  end
  if not config then
    for _, item in ipairs(model.configurations or {}) do
      if item.name == "Debug" or item.name == "" then config = item; break end
    end
  end
  config = config or (model.configurations or {})[1]
  local result = {}
  for _, ref in ipairs(config and config.targets or {}) do
    local target = read_json(dir .. "/.cmake/api/v1/reply/" .. ref.jsonFile)
    if target and target.type == "EXECUTABLE" and target.artifacts and target.artifacts[1] then
      local path = target.artifacts[1].path
      if not vim.startswith(path, "/") and not path:match("^%a:[/\\]") then path = vim.fs.joinpath(dir, path) end
      result[#result + 1] = { name = target.name, path = path }
    end
  end
  table.sort(result, function(a, b) return a.name < b.name end)
  return result
end
local function strip_ansi(text)
  return text:gsub("\27%[[%d;?]*%a", "")
end
local function normalize_cmake(lines)
  local result = {}
  for _, line in ipairs(lines) do
    local file, lnum, func = line:match("^CMake Error at (.-):(%d+) %((.-)%)%s*:?%s*$")
    if file then
      result[#result + 1] = ("%s:%s: error: CMake error in %s"):format(file, lnum, func)
    else
      file, lnum, func = line:match("^CMake Warning at (.-):(%d+) %((.-)%)%s*:?%s*$")
      if not file then
        file, lnum, func = line:match("^CMake Warning %(.-%) at (.-):(%d+) %((.-)%)%s*:?%s*$")
      end
      if file then
        result[#result + 1] = ("%s:%s: warning: CMake warning in %s"):format(file, lnum, func)
      else
        result[#result + 1] = line
      end
    end
  end
  return result
end
local function errorformat()
  local extra = {
    "%f:%l:%c: %trror: %m",
    "%f:%l:%c: %tarning: %m",
    "%f:%l:%c: %tote: %m",
    "%f:%l: %trror: %m",
    "%f:%l: %tarning: %m",
    "%f:%l: %tote: %m",
  }
  return table.concat(extra, ",") .. "," .. vim.o.errorformat
end
local function save_files()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
      local ok, err = pcall(vim.api.nvim_buf_call, buf, function() vim.cmd("silent write") end)
      if not ok then return nil, err end
    end
  end
  return true
end
function M.is_executable(path)
  return vim.fn.filereadable(path) == 1 or vim.fn.executable(path) == 1
end
function M.refresh(root, target)
  if M.is_executable(target.path) then return target end
  for _, item in ipairs(M.targets(root)) do
    if item.name == target.name then return item end
  end
  return nil
end
function M.execute(root, argv, callback)
  if M.jobs[root] then notify("A project task is already running", vim.log.levels.WARN); return end
  if vim.fn.executable(argv[1]) ~= 1 then notify("Missing build tool: " .. argv[1], vim.log.levels.ERROR); return end
  local saved, err = save_files()
  if not saved then notify(tostring(err), vim.log.levels.ERROR); return end
  local title = table.concat(argv, " ")
  notify("Running: " .. title)
  local ok, process = pcall(vim.system, argv, { cwd = root, text = true }, function(result)
    vim.schedule(function()
      M.jobs[root] = nil
      if M.last_root == root then M.last_root = nil end
      local output = strip_ansi((result.stdout or "") .. "\n" .. (result.stderr or ""))
      local lines = normalize_cmake(vim.split(output, "\n"))
      table.insert(lines, 1, "Entering directory '" .. root .. "'")
      local parsed = vim.fn.getqflist({ lines = lines, efm = "%DEntering directory '%f'," .. errorformat() }).items
      vim.fn.setqflist({}, " ", { title = title, items = parsed })
      if result.code ~= 0 then
        vim.cmd.copen()
        notify("Task failed (" .. result.code .. "); see quickfix", vim.log.levels.ERROR)
      else
        notify("Task finished")
        if callback then callback() end
      end
    end)
  end)
  if ok then
    M.jobs[root] = process
    M.last_root = root
  else
    notify(tostring(process), vim.log.levels.ERROR)
  end
end
function M.stop()
  local job = M.last_root and M.jobs[M.last_root]
  if job then
    job:kill(15)
    notify("Stopping project task in " .. M.last_root)
  else
    notify("No running build task", vim.log.levels.WARN)
  end
end
function M.configure(root, callback, extra)
  root = root or M.root()
  if vim.fn.filereadable(root .. "/CMakeLists.txt") == 0 then
    notify("No CMakeLists.txt in " .. root, vim.log.levels.WARN); return
  end
  local dir = M.build_dir(root)
  vim.fn.mkdir(dir .. "/.cmake/api/v1/query", "p")
  vim.fn.writefile({}, dir .. "/.cmake/api/v1/query/codemodel-v2")
  local argv = { "cmake", "-S", root, "-B", dir, "-DCMAKE_BUILD_TYPE=" .. M.build_type(), "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" }
  if vim.fn.filereadable(dir .. "/CMakeCache.txt") == 0 and vim.fn.executable("ninja") == 1 then
    vim.list_extend(argv, { "-G", "Ninja" })
  end
  vim.list_extend(argv, extra or {})
  M.execute(root, argv, function()
    M.selections[root] = nil
    require("lsp").restart_clangd()
    if callback then callback() end
  end)
end
function M.build(callback, root, all)
  root = root or M.root()
  if vim.fn.filereadable(root .. "/CMakeLists.txt") == 1 then
    local dir = M.build_dir(root)
    local function build()
      local argv = { "cmake", "--build", dir, "--config", M.build_type(), "--parallel" }
      if not all and M.selections[root] then vim.list_extend(argv, { "--target", M.selections[root].name }) end
      M.execute(root, argv, callback)
    end
    local cached_type = configured_build_type(dir)
    if vim.fn.filereadable(dir .. "/CMakeCache.txt") == 0 or (cached_type and cached_type ~= M.build_type()) then
      local selection = M.selections[root]
      M.configure(root, function()
        if selection then
          for _, item in ipairs(M.targets(root)) do
            if item.name == selection.name then M.selections[root] = item; break end
          end
        end
        build()
      end)
    else
      build()
    end
  elseif vim.fn.filereadable(root .. "/Makefile") == 1 then
    M.execute(root, { "make", "-j2" }, callback)
  else
    notify("No CMakeLists.txt or Makefile. Use :DevDebug for an existing executable", vim.log.levels.WARN)
  end
end
function M.input_executable(root, callback)
  vim.ui.input({ prompt = "Path to executable: ", default = M.build_dir(root) .. "/", completion = "file" }, function(path)
    if not path or path == "" then return end
    path = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
    if vim.fn.filereadable(path) ~= 1 then
      notify("Executable not found: " .. path, vim.log.levels.ERROR)
      return
    end
    callback({ name = vim.fs.basename(path), path = path })
  end)
end
function M.select(root, callback, force)
  root = root or M.root()
  if not force and M.selections[root] then callback(M.selections[root]); return end
  local targets = M.targets(root)
  if #targets == 1 and not force then
    M.selections[root] = targets[1]; callback(targets[1]); return
  end
  if #targets > 0 then
    vim.ui.select(targets, { prompt = "Executable target", format_item = function(item) return item.name end }, function(item)
      if item then M.selections[root] = item; callback(item) end
    end)
  else
    M.input_executable(root, callback)
  end
end
function M.arguments(callback)
  vim.ui.input({ prompt = 'Arguments (JSON array, e.g. ["--file", "a b.txt"]): ', default = "[]" }, function(value)
    if not value then return end
    local ok, args = pcall(vim.json.decode, value)
    if not ok or type(args) ~= "table" or not vim.islist(args) then notify("Expected a JSON array", vim.log.levels.ERROR); return end
    for _, arg in ipairs(args) do
      if type(arg) ~= "string" then notify("Arguments must be strings", vim.log.levels.ERROR); return end
    end
    callback(args)
  end)
end
local function run_target(root, target)
  local refreshed = M.refresh(root, target)
  if refreshed then
    target = refreshed
    if M.selections[root] then M.selections[root] = target end
  end
  if not M.is_executable(target.path) then
    notify("Executable not found: " .. target.path .. "; run :DevTarget", vim.log.levels.ERROR)
    return
  end
  M.arguments(function(args)
    vim.cmd("botright 12new")
    local ok, job = pcall(vim.fn.jobstart, vim.list_extend({ target.path }, args), { cwd = root, term = true })
    if not ok or job <= 0 then
      vim.cmd("silent! close")
      notify("Failed to start: " .. target.path, vim.log.levels.ERROR)
      return
    end
    vim.cmd.startinsert()
  end)
end
function M.run()
  local root = M.root()
  if #M.targets(root) > 0 or M.selections[root] then
    M.select(root, function(target)
      M.build(function() run_target(root, target) end, root)
    end)
  else
    M.build(function()
      M.select(root, function(target) run_target(root, target) end)
    end, root)
  end
end
function M.setup()
  vim.api.nvim_create_user_command("DevConfigure", function(opts) M.configure(nil, nil, split_args(opts.args)) end, { nargs = "*" })
  vim.api.nvim_create_user_command("DevBuild", function() M.build() end, {})
  vim.api.nvim_create_user_command("DevRun", M.run, {})
  vim.api.nvim_create_user_command("DevTarget", function() M.select(nil, function() end, true) end, {})
  vim.api.nvim_create_user_command("DevStop", M.stop, {})
  vim.api.nvim_create_user_command("DevTest", function()
    local root = M.root()
    M.build(function() M.execute(root, { "ctest", "--test-dir", M.build_dir(root), "-C", M.build_type(), "--output-on-failure" }) end, root, true)
  end, {})
  for keys, command in pairs({
    ["<leader>pc"] = "DevConfigure", ["<leader>pb"] = "DevBuild", ["<leader>pr"] = "DevRun",
    ["<leader>pt"] = "DevTarget", ["<leader>ps"] = "DevStop", ["<leader>pT"] = "DevTest",
    ["<F7>"] = "DevBuild", ["<F6>"] = "DevRun",
  }) do
    vim.keymap.set("n", keys, "<cmd>" .. command .. "<CR>", { desc = command })
  end
end
return M
