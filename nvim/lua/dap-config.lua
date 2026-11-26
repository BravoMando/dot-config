-- nvim/lua/dap-config.lua
local dap = require("dap")
local project = require("project")
dap.adapters.codelldb = function(callback)
  local suffix = vim.fn.has("win32") == 1 and ".exe" or ""
  local executable = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb" .. suffix
  if vim.fn.executable(executable) ~= 1 then
    vim.notify("CodeLLDB is not ready. Check :Mason or run :DevToolsInstall", vim.log.levels.ERROR)
    return
  end
  callback({ type = "server", port = "${port}", executable = { command = executable, args = { "--port", "${port}" } } })
end
local function run_debugger(root, target)
  project.arguments(function(args)
    dap.run({
      name = target.name,
      type = "codelldb",
      request = "launch",
      program = target.path,
      cwd = root,
      args = args,
      stopOnEntry = false,
      terminal = "integrated",
    })
  end)
end
local function run_project_config(root, build)
  local path = root .. "/.nvim/debug.lua"
  local stat, err, code = vim.uv.fs_stat(path)
  if not stat and code == "ENOENT" then return false end
  local function failed(message)
    vim.notify("Invalid debug configuration " .. path .. ": " .. tostring(message), vim.log.levels.ERROR)
    return true
  end
  if not stat then return failed(err) end
  if stat.type ~= "file" then return failed("Expected a Lua file") end
  local ok, config = pcall(dofile, path)
  if not ok then return failed(config) end
  if type(config) ~= "table" or vim.islist(config) then return failed("Return a single DAP configuration table") end
  config = vim.tbl_extend("keep", config, {
    name = "Project debug",
    type = "codelldb",
    request = "launch",
    cwd = root,
    args = {},
    stopOnEntry = false,
    terminal = "integrated",
  })
  for _, key in ipairs({ "name", "type", "request" }) do
    if type(config[key]) ~= "string" or config[key] == "" then return failed(key .. " must be a non-empty string") end
  end
  if config.request ~= "launch" and config.request ~= "attach" then return failed("request must be launch or attach") end
  if config.request == "launch" and not (type(config.program) == "function" or (type(config.program) == "string" and config.program ~= "")) then
    return failed("program must be an executable path or a function returning one")
  end
  local function run() dap.run(config) end
  if build and config.request == "launch" then
    project.build(run, root, true)
  else
    run()
  end
  return true
end
local function debug_target(root, target)
  local refreshed = project.refresh(root, target)
  if refreshed then
    target = refreshed
    if project.selections[root] then project.selections[root] = target end
  end
  if not project.is_executable(target.path) then
    vim.notify("Executable not found: " .. target.path .. "; run :DevTarget", vim.log.levels.ERROR)
    return
  end
  run_debugger(root, target)
end
local function debug_executable()
  if dap.session() then
    dap.continue()
    return
  end
  local root = project.root()
  if run_project_config(root, false) then return end
  if project.selections[root] then
    debug_target(root, project.selections[root])
    return
  end
  project.input_executable(root, function(target) run_debugger(root, target) end)
end
local function launch(build)
  if dap.session() then dap.continue(); return end
  local root = project.root()
  if run_project_config(root, build) then return end
  local function selected(target)
    if build then
      project.build(function() debug_target(root, target) end, root)
    else
      debug_target(root, target)
    end
  end
  if #project.targets(root) > 0 or project.selections[root] then
    project.select(root, selected)
  elseif build then
    project.build(function() project.select(root, selected) end, root)
  else
    project.select(root, selected)
  end
end
dap.configurations.c = {
  {
    name = "Attach to process",
    type = "codelldb",
    request = "attach",
    pid = require("dap.utils").pick_process,
  },
}
dap.configurations.cpp = dap.configurations.c
require("nvim-dap-virtual-text").setup({ commented = true, clear_on_continue = true })
require("dap-view").setup({
  auto_toggle = true,
  winbar = {
    sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl", "console" },
    default_section = "scopes",
    controls = { enabled = true },
  },
})
vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", linehl = "Visual" })
vim.api.nvim_create_user_command("DevDebug", function(opts) launch(not opts.bang) end, { bang = true })
vim.keymap.set("n", "<F5>", debug_executable, { desc = "Debug an executable / Continue" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step into" })
vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step out" })
vim.keymap.set("n", "<S-F5>", dap.terminate, { desc = "Debug: Terminate" })
vim.keymap.set("n", "<leader>dd", function() launch(true) end, { desc = "Build and debug / Continue" })
vim.keymap.set("n", "<leader>da", function() dap.run(dap.configurations.c[1]) end, { desc = "Debug: Attach to process" })
vim.keymap.set("n", "<leader>dq", dap.terminate, { desc = "Debug: Terminate" })
vim.keymap.set("n", "<leader>dQ", function() if dap.session() then dap.disconnect() end end, { desc = "Debug: Detach" })
vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Debug: Run last (no build)" })
vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle breakpoint" })
vim.keymap.set("n", "<leader>B", function()
  vim.ui.input({ prompt = "Breakpoint condition: " }, function(value) if value then dap.set_breakpoint(value) end end)
end, { desc = "Debug: Conditional breakpoint" })
vim.keymap.set("n", "<leader>dp", function()
  vim.ui.input({ prompt = "Log message: " }, function(value) if value then dap.set_breakpoint(nil, nil, value) end end)
end, { desc = "Debug: Logpoint" })
vim.keymap.set("n", "<leader>dv", "<cmd>DapViewToggle<CR>", { desc = "Debug: Toggle view" })
vim.keymap.set("n", "<leader>dc", "<cmd>DapViewClose<CR>", { desc = "Debug: Close view" })
vim.keymap.set({ "n", "x" }, "<leader>dw", "<cmd>DapViewWatch<CR>", { desc = "Debug: Watch expression" })
vim.keymap.set("n", "<leader>de", function() require("dap.ui.widgets").hover() end, { desc = "Debug: Evaluate expression" })
for key, section in pairs({ W = "watches", S = "scopes", E = "exceptions", B = "breakpoints", T = "threads", R = "repl", C = "console" }) do
  vim.keymap.set("n", "<leader>d" .. key, "<cmd>DapViewJump " .. section .. "<CR>", { desc = "Debug: " .. section })
end
