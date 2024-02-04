vim.g.mapleader = ' '

vim.keymap.set({ 'v', 'x' }, '<leader>y', '"+y')
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])

vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

vim.keymap.set({ 'n', 'x' }, 'x', '"_x')
vim.keymap.set({ 'n', 'x' }, 'X', '"_d')

vim.keymap.set('n', '<leader>w', '<cmd>write<cr>')
vim.keymap.set('n', '<leader><leader>', ':source<cr>')
vim.keymap.set('n', '<leader>pv', vim.cmd.Broot)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

vim.keymap.set('n', '<C-S-r>', 'gg=G')

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set("n", "<leader><leader>", function()
	vim.cmd("so")
end)

vim.keymap.set('n', 'ZZ', function()
	local filetype = vim.api.nvim_buf_get_option(0, "filetype")
	local filename = vim.fn.expand('%:p')
	if filetype ~= 'netrw' and filename ~= '' then
		vim.cmd(':w')
		vim.cmd(':Explore')
	else
		vim.cmd(':exit')
	end
end)

function open_broot_in_path(path, args)
	local expanded_path = vim.fn.expand(path)
	vim.fn["g:OpenBrootInPathInWindow"](expanded_path, args)
end

-- Create Vim commands using the lua command
vim.api.nvim_set_keymap('n', '<Leader>bc', ':lua open_broot_in_path("%:p:h", "")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>bw', ':lua open_broot_in_path(".", "")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>bh', ':lua open_broot_in_path("~", "")<CR>', { noremap = true, silent = true })

