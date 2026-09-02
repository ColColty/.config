-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'


  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.3',
    -- or                            , branch = '0.1.x',
    requires = { { 'nvim-lua/plenary.nvim' } }
  }

  use('nvim-treesitter/nvim-treesitter', { run = ':TSUpdate' })
  use('nvim-treesitter/playground')
  use('theprimeagen/harpoon')
  use('mbbill/undotree')
  use('tpope/vim-fugitive')
  use('airblade/vim-gitgutter')
  use('elzr/vim-json')

  use {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    requires = {
      --- Uncomment these if you want to manage LSP servers from neovim
      { 'williamboman/mason.nvim' },
      { 'williamboman/mason-lspconfig.nvim' },

      -- LSP Support
      { 'neovim/nvim-lspconfig' },
      -- Autocompletion
      { 'hrsh7th/nvim-cmp' },
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'L3MON4D3/LuaSnip' },
      { 'hrsh7th/cmp-path' },
    }
  }

  use('neovim/nvim-lspconfig')
  use('jose-elias-alvarez/null-ls.nvim')
  use('MunifTanjim/prettier.nvim')

  use {
    "pmizio/typescript-tools.nvim",
    requires = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" }
  }

  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'nvim-tree/nvim-web-devicons', opt = true }
  }

  use('windwp/nvim-ts-autotag')
  use('windwp/nvim-autopairs')
  use('ray-x/go.nvim')
  use('wakatime/vim-wakatime')
  use('stevearc/dressing.nvim')
  use { 'dccsillag/magma-nvim', run = ':UpdateRemotePlugins' }
  use('ruanyl/vim-gh-line')
  use('tpope/vim-rails')
  use('github/copilot.vim')
  use('yasuhiroki/circleci.vim')
  use('prisma/vim-prisma')
  use "rebelot/kanagawa.nvim"
  use({
    'AxelGard/oneokai.nvim',
    config = function()
      require('oneokai').setup {
        style = 'darker'
      }
      vim.cmd('colorscheme oneokai')
    end
  })
end)
