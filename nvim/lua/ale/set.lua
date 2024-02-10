vim.g.user42 = 'arubio-o'
vim.g.mail42 = 'arubio-o@student.42madrid.com'

vim.g.strider_auto_open = 1
vim.g.strider_auto_close = 1

vim.api.nvim_set_option('compatible', false)
vim.api.nvim_set_option('filetype', 'plugin')
vim.api.nvim_set_option('syntax', 'on')

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.wrap = true
vim.opt.breakindent = true

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv('HOME') .. '/.nvim/undodir'
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.isfname:append('@-@')

vim.opt.updatetime = 50

vim.opt.colorcolumn = '80'
