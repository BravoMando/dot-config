-- nvim/init.lua
if vim.fn.has("nvim-0.12") == 0 then
  error("This configuration requires Neovim 0.12 or newer")
end
vim.g.mapleader = " "
vim.g.maplocalleader = " "
local function load(name)
  local ok, result = pcall(require, name)
  if not ok then
    vim.notify(("Failed to load %s: %s"):format(name, result), vim.log.levels.ERROR)
  end
  return ok, result
end
local ok, project = load("project")
load("basic")
load("plugins")
load("colorscheme")
load("devicons")
load("mason-tools")
load("fuzzy")
load("mini-files")
load("completion")
load("lsp")
load("treesitter")
load("markdown")
load("editing")
if ok then
  local setup_ok, err = pcall(project.setup)
  if not setup_ok then
    vim.notify(("Failed to set up project commands: %s"):format(err), vim.log.levels.ERROR)
  end
end
load("dap-config")
