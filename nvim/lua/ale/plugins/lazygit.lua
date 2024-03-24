return {
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		dependencies = {
			"nvim-lua/plenary.nvim"
		},
		config = function()
			vim.keymap.set('n', '<leader>g', ':LazyGit<CR>', { silent = true })
		end,
	},
}
