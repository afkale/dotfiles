local telescope = require('telescope.builtin')

vim.keymap.set('n', '<leader>f', telescope.live_grep, {})
vim.keymap.set('n', '<leader>ff', telescope.find_files, {})
vim.keymap.set('n', '<leader>fg', telescope.git_files, {})
vim.keymap.set('n', '<leader>fb', telescope.buffers, {})
vim.keymap.set('n', '<leader>fs', telescope.lsp_document_symbols, {})
vim.keymap.set('n', '<leader>fw', telescope.grep_string, {})
