vim.g.mapleader = ' '

vim.keymap.set({'v', 'x'}, '<leader>y', '"+y')

vim.keymap.set({'n', 'x'}, 'x', '"_x')
vim.keymap.set({'n', 'x'}, 'X', '"_d')

vim.keymap.set('n', '<leader>w', '<cmd>write<cr>')
vim.keymap.set('n', '<leader><leader>', ':source<cr>')
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)

vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

vim.keymap.set('n', 'ZZ', function()
	local filetype = vim.api.nvim_buf_get_option(0, "filetype")
	if  filetype ~= 'netrw' and filetype ~= '' then
		vim.cmd(':w')
		vim.cmd(':Explore')
	else
		vim.cmd(':exit')
	end
end)
