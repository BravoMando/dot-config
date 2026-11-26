-- nvim/lua/editing.lua
require("mini.statusline").setup()
require("mini.pairs").setup()
require("mini.surround").setup()
require("mini.ai").setup()
require("mini.diff").setup()
require("mini.clue").setup({
  triggers = {
    { mode = "n", keys = "<leader>" },
    { mode = "x", keys = "<leader>" },
    { mode = "n", keys = "g" },
    { mode = "n", keys = "[" },
    { mode = "n", keys = "]" },
  },
  clues = {
    require("mini.clue").gen_clues.g(),
    { mode = "n", keys = "<leader>c", desc = "+Code" },
    { mode = "n", keys = "<leader>d", desc = "+Debug" },
    { mode = "n", keys = "<leader>f", desc = "+Find" },
    { mode = "n", keys = "<leader>p", desc = "+Project" },
  },
  window = { delay = 300 },
})
