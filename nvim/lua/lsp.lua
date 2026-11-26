-- nvim/lua/lsp.lua
local M = {}
local group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true })
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
vim.lsp.config("*", { capabilities = capabilities })
function M.clangd_args(root)
  local argv = { "clangd", "--background-index", "--completion-style=detailed", "--header-insertion=iwyu", "--fallback-style=LLVM" }
  if root and vim.fn.filereadable(root .. "/.clang-tidy") == 1 then argv[#argv + 1] = "--clang-tidy" end
  return argv
end
local function clangd_cmd(dispatchers, config)
  local root = config.root_dir or require("project").root()
  return vim.lsp.rpc.start(M.clangd_args(root), dispatchers, { cwd = config.cmd_cwd, env = config.cmd_env, detached = config.detached })
end
vim.lsp.config("clangd", {
  cmd = clangd_cmd,
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_dir = function(buf, on_dir) on_dir(require("project").root(buf)) end,
  before_init = function(params, config)
    local root = config.root_dir
    local dir = require("project").build_dir(root)
    if not vim.uv.fs_stat(root .. "/compile_commands.json") and vim.uv.fs_stat(dir .. "/compile_commands.json") then
      params.initializationOptions = vim.tbl_extend("force", params.initializationOptions or {}, { compilationDatabasePath = dir })
    end
  end,
})
vim.lsp.config("neocmake", {
  cmd = { "neocmakelsp", "stdio" },
  filetypes = { "cmake" },
  root_dir = function(buf, on_dir) on_dir(require("project").root(buf)) end,
})
function M.enable()
  for name, executable in pairs({ clangd = "clangd", neocmake = "neocmakelsp" }) do
    if vim.fn.executable(executable) == 1 then vim.lsp.enable(name) end
  end
end
function M.restart_clangd()
  if #vim.lsp.get_clients({ name = "clangd" }) > 0 then
    vim.cmd("lsp restart clangd")
  else
    M.enable()
  end
end
vim.api.nvim_create_user_command("DevLspRestart", M.restart_clangd, {})
vim.api.nvim_create_autocmd("User", { group = group, pattern = "DevToolReady", callback = M.enable })
M.enable()
vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  virtual_text = { spacing = 2, source = "if_many" },
  float = { border = "rounded", source = true },
  signs = { text = { [1] = "E", [2] = "W", [3] = "I", [4] = "H" } },
})
local function is_cxx(buf)
  local filetype = vim.bo[buf].filetype
  return filetype == "c" or filetype == "cpp" or filetype == "objc" or filetype == "objcpp"
end
function M.format_external(buf)
  if not is_cxx(buf) or vim.fn.executable("clang-format") ~= 1 then return false end
  local name = vim.api.nvim_buf_get_name(buf)
  local input = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"
  local argv = { "clang-format", "--style=file", "--fallback-style=LLVM" }
  if name ~= "" then argv[#argv + 1] = "--assume-filename=" .. name end
  local ok, process = pcall(vim.system, argv, { stdin = input, text = true })
  if not ok then return false end
  local result = process:wait(3000)
  if not result or result.code ~= 0 or not result.stdout then return false end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result.stdout:gsub("\n$", ""), "\n", { plain = true }))
  return true
end
function M.format(buf, opts)
  opts = opts or {}
  if #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" }) > 0 then
    vim.lsp.buf.format({ bufnr = buf, timeout_ms = 3000 })
    return true
  end
  if M.format_external(buf) then return true end
  if not opts.quiet then
    vim.notify("Formatter is not ready; check :Mason and :checkhealth cxx", vim.log.levels.WARN)
  end
  return false
end
vim.api.nvim_create_user_command("DevFormat", function() M.format(0) end, { desc = "Format current buffer" })
vim.keymap.set("n", "<leader>cf", function() M.format(0) end, { desc = "Format file" })
vim.api.nvim_create_autocmd("LspDetach", {
  group = group,
  callback = function(ev) pcall(vim.api.nvim_del_augroup_by_name, "UserLspHighlight" .. ev.buf) end,
})
vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/documentHighlight") then
      local highlight_group = vim.api.nvim_create_augroup("UserLspHighlight" .. ev.buf, { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = highlight_group,
        buffer = ev.buf,
        callback = function()
          if #vim.lsp.get_clients({ bufnr = ev.buf, method = "textDocument/documentHighlight" }) > 0 then
            vim.lsp.buf.document_highlight()
          end
        end,
      })
      vim.api.nvim_create_autocmd("CursorMoved", {
        group = highlight_group,
        buffer = ev.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end
    local function map(keys, fn, desc, mode)
      vim.keymap.set(mode or "n", keys, fn, { buffer = ev.buf, desc = desc })
    end
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("K", vim.lsp.buf.hover, "Hover documentation")
    map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "x" })
    map("<leader>ch", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
    end, "Toggle inlay hints")
    if client and client.name == "clangd" then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
      map("<leader>ct", function() vim.lsp.buf.typehierarchy("subtypes") end, "Type hierarchy: subtypes")
      map("<leader>cT", function() vim.lsp.buf.typehierarchy("supertypes") end, "Type hierarchy: supertypes")
      map("<leader>cs", function()
        client:request("textDocument/switchSourceHeader", vim.lsp.util.make_text_document_params(ev.buf), function(err, uri)
          if err then vim.notify(err.message, vim.log.levels.ERROR)
          elseif uri and uri ~= "" then vim.cmd.edit(vim.fn.fnameescape(vim.uri_to_fname(uri)))
          else vim.notify("No matching source/header") end
        end, ev.buf)
      end, "Switch source/header")
    end
  end,
})
vim.keymap.set("n", "<leader>ce", vim.diagnostic.open_float, { desc = "Show diagnostic" })
vim.keymap.set("n", "<leader>cl", vim.diagnostic.setqflist, { desc = "Diagnostics to quickfix" })
vim.g.cxx_format_on_save = true
vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  pattern = { "*.c", "*.h", "*.cpp", "*.hpp", "*.cc", "*.hh", "*.cxx", "*.hxx" },
  callback = function(ev)
    if vim.g.cxx_format_on_save then pcall(M.format, ev.buf, { quiet = true }) end
  end,
})
vim.keymap.set("n", "<leader>cF", function()
  vim.g.cxx_format_on_save = not vim.g.cxx_format_on_save
  vim.notify("Format on save: " .. tostring(vim.g.cxx_format_on_save))
end, { desc = "Toggle format on save" })
return M
