-- Set leader key first (before lazy)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("tforne.set")
require("tforne.remap")
require("tforne.mem")

-- Setup lazy.nvim
require("lazy").setup("plugins")
