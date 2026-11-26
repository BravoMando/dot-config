-- nvim/lua/markdown.lua
require("render-markdown").setup({
  file_types = { "markdown" },
  render_modes = { "n", "c" },
  latex = { enabled = false },
})
vim.keymap.set("n", "<leader>mp", "<cmd>RenderMarkdown toggle<CR>", { desc = "Toggle Markdown rendering" })
