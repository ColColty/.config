vim.keymap.set("n", "<leader>r", ':MagmaEvaluateOperator<CR>')
vim.keymap.set("n", "<leader>rr", ':MagmaEvaluateLine<CR>')
vim.keymap.set("x", "<leader>r", ':<C-u>MagmaEvaluateVisual<CR>')
vim.keymap.set("n", "<leader>rc", ':MagmaReevaluateCell<CR>')
vim.keymap.set("n", "<leader>rd", ':MagmaDelete<CR>')
vim.keymap.set("n", "<leader>ro", ':MagmaShowOutput<CR>')

