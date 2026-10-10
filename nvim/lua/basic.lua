-- ~/.config/nvim/lua/basic.lua
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.scrolloff = 5
vim.opt.sidescroll = 5

vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"

vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.textwidth = 80
vim.opt.colorcolumn = "81"
vim.opt.wrap = true
vim.opt.linebreak = true

vim.opt.formatoptions = "tcq"
vim.opt.termguicolors = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

vim.opt.list = true
-- local dot = '\xC2\xB7'
-- local end = '\xE2\x80\xA2'
-- local newline = '\xE2\x86\xB5'
vim.opt.listchars = {
  space = '\xC2\xB7',
  trail = '\xE2\x80\xA2',
  eol = '\xE2\x86\xB5',
}

