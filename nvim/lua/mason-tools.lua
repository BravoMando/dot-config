-- nvim/lua/mason-tools.lua
local M = {}
M.packages = { "clangd", "clang-format", "neocmakelsp", "codelldb", "tree-sitter-cli" }
require("mason").setup({ PATH = "prepend" })
local function ready(name)
  vim.api.nvim_exec_autocmds("User", { pattern = "DevToolReady", data = { package = name } })
end
function M.install()
  local registry = require("mason-registry")
  registry.refresh(function(success)
    vim.schedule(function()
      if not success then
        vim.notify("Tool registry unavailable. See :MasonLog; retry :DevToolsInstall", vim.log.levels.ERROR)
        return
      end
      for _, name in ipairs(M.packages) do
        local ok, pkg = pcall(registry.get_package, name)
        if not ok then
          vim.notify("Missing Mason package: " .. name, vim.log.levels.ERROR)
        elseif pkg:is_installed() then
          ready(name)
        elseif not pkg:is_installing() then
          pkg:once("install:success", vim.schedule_wrap(function() ready(name) end))
          pkg:once("install:failed", vim.schedule_wrap(function()
            vim.notify("Install failed: " .. name .. ". See :MasonLog; retry :DevToolsInstall", vim.log.levels.ERROR)
          end))
          pkg:install()
        end
      end
    end)
  end)
end
vim.api.nvim_create_user_command("DevToolsInstall", M.install, {})
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("DevTools", { clear = true }),
  once = true,
  callback = function() vim.schedule(M.install) end,
})
return M
