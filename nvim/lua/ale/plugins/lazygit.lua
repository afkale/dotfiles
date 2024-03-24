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
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim"
		},
		config = function()
			require("telescope").load_extension("lazygit")
			vim.keymap.set('n', '<leader>g', ':LazyGit<CR>', { silent = true })
		end,
	},
}
