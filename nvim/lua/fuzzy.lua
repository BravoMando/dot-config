-- nvim/lua/fuzzy.lua
local fzf = require("fzf-lua")
fzf.setup({
  fzf_bin = "fzf",
  files = { file_icons = "devicons" },
  grep = {
    rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob !.git --max-columns=4096 -e",
    file_icons = "devicons",
  },
})
if vim.fn.executable("fzf") == 1 then fzf.register_ui_select() end
local function project_files()
  local cmd
  if vim.fn.executable("fd") == 1 then
    cmd = "fd --type f --type l --hidden --exclude .git --color never"
  elseif vim.fn.executable("fdfind") == 1 then
    cmd = "fdfind --type f --type l --hidden --exclude .git --color never"
  elseif vim.fn.executable("rg") == 1 then
    cmd = "rg --files --hidden --glob !.git --color never"
  else
    vim.notify("File search requires fd (or fdfind) or ripgrep. See :checkhealth cxx", vim.log.levels.ERROR)
    return
  end
  fzf.files({ cwd = require("project").root(), cmd = cmd })
end
local function project_grep()
  if vim.fn.executable("rg") ~= 1 then
    vim.notify("Content search requires ripgrep. See :checkhealth cxx", vim.log.levels.ERROR)
    return
  end
  fzf.live_grep({ cwd = require("project").root() })
end
vim.keymap.set("n", "<leader>ff", project_files, { desc = "Find project files" })
vim.keymap.set("n", "<leader>fg", project_grep, { desc = "Search project" })
vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fh", fzf.help_tags, { desc = "Find help" })
vim.keymap.set("n", "<leader>fk", fzf.keymaps, { desc = "Find keymaps" })
vim.keymap.set("n", "<leader>fs", fzf.lsp_document_symbols, { desc = "Document symbols" })
vim.keymap.set("n", "<leader>fS", fzf.lsp_live_workspace_symbols, { desc = "Workspace symbols" })
vim.keymap.set("n", "<leader>fd", fzf.diagnostics_workspace, { desc = "Find diagnostics" })
