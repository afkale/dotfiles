return {
	{
		"ibhagwan/fzf-lua",
		config = function()
			require("fzf-lua").setup({})
			local builtin = require("fzf-lua")

			vim.keymap.set('n', 'fg', builtin.live_grep, {})
			vim.keymap.set('n', 'fd', builtin.grep_curbuf, {})
			vim.keymap.set('n', 'ff', builtin.files, {})
			vim.keymap.set('n', 'fs', builtin.lsp_document_symbols, {})
			vim.keymap.set('n', 'fw', builtin.lsp_live_workspace_symbols, {})
			vim.keymap.set('n', 'fc', builtin.commands, {})
			vim.keymap.set({ 'n', 'v' }, 'fr', builtin.lsp_finder, {})
			vim.keymap.set('n', 'fm', builtin.buffers, {})
		end
	}
}
