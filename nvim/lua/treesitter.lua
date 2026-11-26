-- nvim/lua/treesitter.lua
local M = {}
local ts = require("nvim-treesitter")
ts.setup({ install_dir = vim.fn.stdpath("data") .. "/site" })
local languages = { c = true, cpp = true, lua = true, cmake = true, markdown = true }
local group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true })
local function start(buf)
  if languages[vim.bo[buf].filetype] then
    pcall(vim.treesitter.start, buf)
  end
end
function M.install()
  if vim.fn.executable("tree-sitter") ~= 1 then
    vim.notify("tree-sitter CLI is not ready. Run :DevToolsInstall", vim.log.levels.WARN)
    return
  end
  local compiler = false
  for _, name in ipairs({ "cc", "gcc", "clang", "cl" }) do
    compiler = compiler or vim.fn.executable(name) == 1
  end
  if not compiler then
    vim.notify("A C compiler is required for Tree-sitter parsers. Install one and run :DevParsersInstall", vim.log.levels.WARN)
    return
  end
  ts.install({ "c", "cpp", "lua", "cmake", "markdown", "markdown_inline" }):await(function(err)
    vim.schedule(function()
      if err then vim.notify(tostring(err), vim.log.levels.ERROR); return end
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then start(buf) end
      end
    end)
  end)
end
vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  group = group,
  callback = function(ev) start(ev.buf) end,
})
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "DevToolReady",
  callback = function(ev)
    if ev.data.package == "tree-sitter-cli" then M.install() end
  end,
})
vim.api.nvim_create_user_command("DevParsersInstall", M.install, {})
return M
