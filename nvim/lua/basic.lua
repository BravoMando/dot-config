-- nvim/lua/basic.lua
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5
if vim.fn.has("clipboard") == 1 then vim.opt.clipboard = "unnamedplus" end
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.confirm = true
vim.opt.undofile = true
vim.opt.wrap = false
vim.opt.textwidth = 0
vim.opt.colorcolumn = "81"
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.list = true
vim.opt.listchars = {
  space = '\xC2\xB7',
  trail = '\xE2\x80\xA2',
  eol = '\xE2\x86\xB5',
  tab   = '\x2D\x3E',
}
vim.opt.foldlevel = 99
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
vim.keymap.set({ "n", "x" }, "<leader>v", "<C-v>", { desc = "Visual block" })
vim.keymap.set("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>copen<CR>", { desc = "Open quickfix" })
vim.keymap.set("n", "[q", "<cmd>cprevious<CR>", { desc = "Previous build error" })
vim.keymap.set("n", "]q", "<cmd>cnext<CR>", { desc = "Next build error" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })
local filetypes = vim.api.nvim_create_augroup("EditorFiletypes", { clear = true })
local function keep_tabs(buf)
  vim.bo[buf].expandtab = false
  vim.bo[buf].softtabstop = 0
end
local tab_filetypes = { make = true, automake = true, tsv = true }
local function keep_file_tabs(buf)
  if tab_filetypes[vim.bo[buf].filetype] then
    keep_tabs(buf)
    vim.bo[buf].shiftwidth = 0
  end
end
vim.api.nvim_create_autocmd("FileType", {
  group = filetypes,
  pattern = "*",
  callback = function(args)
    vim.opt_local.formatoptions:remove({ "t", "o" })
  end,
})
vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  group = filetypes,
  callback = function(args) keep_file_tabs(args.buf) end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = filetypes,
  pattern = { "dap-repl", "dap-float", "dap-view", "dap-view-*" },
  callback = function(args) keep_tabs(args.buf) end,
})
vim.api.nvim_create_autocmd("InsertEnter", {
  group = filetypes,
  callback = function(args)
    keep_file_tabs(args.buf)
    if vim.bo[args.buf].buftype ~= "" and vim.api.nvim_win_get_config(0).relative ~= "" then
      keep_tabs(args.buf)
      vim.wo.list = true
    end
  end,
})
