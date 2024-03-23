return {
	{
		'nvim-telescope/telescope.nvim',
		tag = '0.1.6',
		dependencies = { 'nvim-lua/plenary.nvim' },
		config = function()
			local builtin = require('telescope.builtin')

			vim.keymap.set('n', 'fg', builtin.live_grep, {})
			vim.keymap.set('n', 'ff', builtin.find_files, {})
			vim.keymap.set('n', 'fs', builtin.lsp_document_symbols, {})
			vim.keymap.set('n', 'fw', builtin.grep_string, {})
			vim.keymap.set('n', 'fl', function()
				builtin.current_buffer_fuzzy_find(
					require('telescope.themes').get_dropdown({
						winblend = 10,
						previewer = false
					})
				)
			end, {})

			vim.keymap.set('n', 'gs', builtin.git_status, {})
			vim.keymap.set('n', 'gb', builtin.git_branches, {})
			vim.keymap.set('n', 'gf', builtin.git_files, {})

			vim.keymap.set('n', 'ms', builtin.buffers, {})
		end
	}
}
