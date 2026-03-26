-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Screen Down, Center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Screen Up, Center" })
vim.keymap.set("n", "n", "nzz", { desc = "Find Next, Center" })
vim.keymap.set('n', '<leader>fw', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Replace All Word' })

-- Move Lines
-- TODO: Not working with A or M
vim.keymap.set("n", "<M-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
vim.keymap.set("n", "<M-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
vim.keymap.set("i", "<M-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
vim.keymap.set("i", "<M-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
vim.keymap.set("v", "<M-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
vim.keymap.set("v", "<M-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

local wk = require("which-key")
wk.add({
  { "<leader>a", group = "AI" }, -- group
})

-- Override LazyVim's default terminal toggle to use a single shared instance
-- rooted in nvim's startup directory instead of per-buffer project root.
-- count=1 (default) for the right split so it's the "primary" terminal;
-- count=2 for the bottom terminal to keep them separate.
local startup_cwd = vim.uv.cwd()
vim.keymap.set({ "n", "t" }, "<C-/>", function()
  Snacks.terminal(nil, { cwd = startup_cwd, count = 2 })
end, { desc = "Toggle Terminal (Bottom)" })
vim.keymap.set({ "n", "t" }, "<C-_>", function()
  Snacks.terminal(nil, { cwd = startup_cwd, count = 2 })
end, { desc = "Toggle Terminal (Bottom)" })

vim.keymap.set({ "n", "t" }, "<C-\\>", function()
  Snacks.terminal(nil, { cwd = startup_cwd, win = { position = "right", stack = false } })
end, { desc = "Toggle Terminal (Right Split)" })
