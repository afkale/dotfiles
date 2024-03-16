vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
	-- Packer can manage itself
	use({ 'wbthomason/packer.nvim' })
	use({
		'nvim-telescope/telescope.nvim',
		tag = '0.1.5',
		-- or                            , branch = '0.1.x',
		requires = { 'nvim-lua/plenary.nvim' }
	})
	use({
		'nvim-treesitter/nvim-treesitter',
		requires = {
			'nvim-treesitter/nvim-treesitter-textobjects'
		},
		{ run = ':TSUpdate' }
	})
	use({ 'nvim-treesitter/playground' })
	use({ 'mbbill/undotree' })
	use({ 'tpope/vim-fugitive' })
	use({ 'norcalli/nvim-colorizer.lua' })
	use({ 'christoomey/vim-tmux-navigator' })
	use {
		'VonHeikemen/lsp-zero.nvim',
		branch = 'v1.x',
		requires = {
			-- LSP Support
			{ 'neovim/nvim-lspconfig' },
			{ 'williamboman/mason.nvim' },
			{ 'williamboman/mason-lspconfig.nvim' },

			-- Autocompletion
			{ 'hrsh7th/nvim-cmp' },
			{ 'hrsh7th/cmp-buffer' },
			{ 'hrsh7th/cmp-path' },
			{ 'saadparwaiz1/cmp_luasnip' },
			{ 'hrsh7th/cmp-nvim-lsp' },
			{ 'hrsh7th/cmp-nvim-lua' },
			{ 'hrsh7th/cmp-cmdline' },

			-- Snippets
			{ 'L3MON4D3/LuaSnip' },
			{ 'rafamadriz/friendly-snippets' },
			{ 'jose-elias-alvarez/null-ls.nvim' },
		}
	}
	use({ 'vimwiki/vimwiki' })
	use({ 'nvim-tree/nvim-tree.lua' })
	use({ 'catppuccin/nvim', as = 'catppuccin' })
	use({ 'nvim-tree/nvim-web-devicons' })
	use({ 'folke/neodev.nvim' })
	use({
		'folke/todo-comments.nvim',
		config = function()
			require('todo-comments.config').setup()
		end
	})
	use({ 'lewis6991/gitsigns.nvim' })
	use({
		'lukas-reineke/indent-blankline.nvim',
		config = function()
			require("ibl").setup()
		end
	})
	use {
		'numToStr/Comment.nvim',
		config = function()
			require('Comment').setup()
		end
	}
	use({
		'rcarriga/nvim-notify',
		config = function()
			require('notify').setup()
		end
	})
end)
