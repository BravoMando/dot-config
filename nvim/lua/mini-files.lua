-- nvim/lua/mini-files.lua
local MiniFiles = require("mini.files")
local show_hidden = true
local function filter(entry)
  return show_hidden or entry.name:sub(1, 1) ~= "."
end
MiniFiles.setup({
  content = { filter = filter },
  mappings = {
    close = "q", go_in = "l", go_in_plus = "L", go_out = "h", go_out_plus = "H",
    synchronize = "gs", reset = "gr", show_help = "g?",
  },
  windows = { preview = true, width_preview = 80 },
})
vim.keymap.set("n", "<leader>e", function()
  local file = vim.api.nvim_buf_get_name(0)
  MiniFiles.open(file ~= "" and vim.fn.filereadable(file) == 1 and vim.fs.dirname(file) or vim.fn.getcwd())
end, { desc = "Browse current file directory" })
vim.keymap.set("n", "<leader>E", function() MiniFiles.open(vim.fn.getcwd()) end, { desc = "Browse working directory" })
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("UserMiniFiles", { clear = true }),
  pattern = "MiniFilesBufferCreate",
  callback = function(args)
    vim.keymap.set("n", "<leader>w", MiniFiles.synchronize, { buffer = args.data.buf_id, desc = "Synchronize files" })
    vim.keymap.set("n", "g.", function()
      show_hidden = not show_hidden
      MiniFiles.refresh({ content = { filter = filter } })
    end, { buffer = args.data.buf_id, desc = "Toggle hidden files" })
  end,
})
