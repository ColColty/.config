return {
  -- Telescope
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
      vim.keymap.set('n', '<C-p>', builtin.git_files, {})
      vim.keymap.set('n', '<leader>ps', function()
        builtin.grep_string({ search = vim.fn.input("Grep > ") })
      end)
    end
  },

  -- Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master', -- classic API; the new `main` branch removed parsers.ft_to_lang and breaks telescope/ts-autotag
    build = ':TSUpdate',
    config = function()
      -- Parsers are installed once via :TSUpdate / :TSInstall <lang>. We skip
      -- ensure_installed/auto_install because master's installer calls the
      -- deprecated vim.validate every run; the compiled parsers persist anyway.
      require('nvim-treesitter.configs').setup {
        highlight = { enable = true, additional_vim_regex_highlighting = false },
      }
    end,
  },

  -- Harpoon
  {
    'theprimeagen/harpoon',
    config = function()
      local mark = require("harpoon.mark")
      local ui = require("harpoon.ui")
      vim.keymap.set("n", "<leader>a", mark.add_file)
      vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)
      vim.keymap.set("n", "<C-t>", function() ui.nav_file(1) end)
      vim.keymap.set("n", "<C-y>", function() ui.nav_file(2) end)
      vim.keymap.set("n", "<C-g>", function() ui.nav_file(3) end)
      vim.keymap.set("n", "<C-h>", function() ui.nav_file(4) end)
    end
  },

  -- Undotree
  {
    'mbbill/undotree',
    config = function()
      vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
    end
  },

  -- Git
  {
    'tpope/vim-fugitive',
    config = function()
      vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
      vim.keymap.set("n", "<leader>gp", vim.cmd.Git_pull)
    end
  },
  -- Git signs (async, pure-Lua; replaces vim-gitgutter which re-ran `git diff` on every CursorHold)
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end
  },
  { 'ruanyl/vim-gh-line' },

  -- LSP Zero + Mason
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'neovim/nvim-lspconfig',
      'hrsh7th/nvim-cmp',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'L3MON4D3/LuaSnip',
    },
    config = function()
      local lsp = require('lsp-zero')
      lsp.extend_lspconfig()
      lsp.preset('recommend')

      require('mason').setup({
        python = {
          python_executable = "~/.venvs/mason-venv/bin/python"
        }
      })

      local mason_lsp = require('mason-lspconfig')
      mason_lsp.setup({
        ensure_installed = { 'cssls', 'tailwindcss', 'jsonls', 'html', 'ts_ls', 'rust_analyzer', 'eslint', 'lua_ls', 'pylsp' },
        handlers = {
          lsp.default_setup
        },
        automatic_installation = true
      })

      local cmp = require('cmp')
      local cmp_select = { behavior = cmp.SelectBehavior.Select }
      local cmp_mappings = lsp.defaults.cmp_mappings({
        ['<C-i>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-u>'] = cmp.mapping.select_next_item(cmp_select),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<C-Space>'] = cmp.mapping.complete(),
      })

      lsp.set_preferences({
        sign_icons = {}
      })

      cmp.setup({
        mapping = cmp_mappings,
        completion = {
          completeopt = 'menu,menuone,noinsert'
        }
      })

      lsp.on_attach(function(client, bufnr)
        local opts = { buffer = bufnr, remap = false }
        vim.keymap.set("n", 'gd', function() vim.lsp.buf.definition() end, opts)
        vim.keymap.set('n', 'K', function() vim.lsp.buf.hover() end, opts)
        vim.keymap.set('n', '<leader>vws', function() vim.lsp.buf.workspace_symbol() end, opts)
        vim.keymap.set('n', '<leader>vd', function() vim.diagnostic.open_float() end, opts)
        vim.keymap.set('n', '[d', function() vim.diagnostic.goto_next() end, opts)
        vim.keymap.set('n', ']d', function() vim.diagnostic.goto_prev() end, opts)
        vim.keymap.set('n', '<leader>vca', function() vim.lsp.buf.code_action() end, opts)
        vim.keymap.set('n', '<leader>vrr', function() vim.lsp.buf.references() end, opts)
        vim.keymap.set('n', '<leader>vrn', function() vim.lsp.buf.rename() end, opts)
        vim.keymap.set('i', '<C-h>', function() vim.lsp.buf.signature_help() end, opts)
      end)

      lsp.setup()
    end
  },

  -- none-ls (maintained null-ls fork) — prettierd formatting + format-on-save
  {
    'nvimtools/none-ls.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local null_ls = require('null-ls')
      local group = vim.api.nvim_create_augroup('lsp_format_on_save', { clear = false })

      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.prettierd.with({
            filetypes = { 'css', 'scss', 'html', 'json', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
          }),
        },
        on_attach = function(client, bufnr)
          if client:supports_method("textDocument/formatting") then
            vim.keymap.set('n', '<Leader>tf', function()
              vim.lsp.buf.format({ bufnr = bufnr })
            end, { buffer = bufnr, desc = "[lsp] format" })

            vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })
            vim.api.nvim_create_autocmd('BufWritePost', {
              buffer = bufnr,
              group = group,
              callback = function() vim.lsp.buf.format({ bufnr = bufnr }) end,
              desc = "[lsp] format on save",
            })
          end
        end,
      })
    end
  },

  -- Lualine
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup {
        options = {
          icons_enabled = true,
          section_separators = { left = ' ', right = ' ' },
          component_separators = { left = '|', right = '|' },
          disabled_filetypes = {},
          theme = "oneokai"
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch' },
          lualine_c = { {
            'filename',
            file_status = true,
            path = 1
          } },
          lualine_x = {
            { 'diagnostics', sources = { 'nvim_diagnostic' },
              symbols = { error = "X ", warn = "W ", info = '? ', hint = "> " } }, 'encoding', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { { 'filename', file_status = true, path = 1 } },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        extensions = { 'fugitive' }
      }
    end
  },

  -- Auto pairs/tags
  { 'windwp/nvim-ts-autotag' },
  { 'windwp/nvim-autopairs', config = true },

  -- Go
  { 'ray-x/go.nvim' },

  -- Dressing (better UI)
  { 'stevearc/dressing.nvim', config = true },

  -- Magma (Jupyter)
  {
    'dccsillag/magma-nvim',
    build = ':UpdateRemotePlugins',
    config = function()
      vim.keymap.set("n", "<leader>r", ':MagmaEvaluateOperator<CR>')
      vim.keymap.set("n", "<leader>rr", ':MagmaEvaluateLine<CR>')
      vim.keymap.set("x", "<leader>r", ':<C-u>MagmaEvaluateVisual<CR>')
      vim.keymap.set("n", "<leader>rc", ':MagmaReevaluateCell<CR>')
      vim.keymap.set("n", "<leader>rd", ':MagmaDelete<CR>')
      vim.keymap.set("n", "<leader>ro", ':MagmaShowOutput<CR>')
    end
  },

  -- Other utilities
  { 'elzr/vim-json' },
  { 'tpope/vim-rails' },
  { 'prisma/vim-prisma' },
  { 'wakatime/vim-wakatime' },

  -- Colorschemes
  { 'rebelot/kanagawa.nvim' },
  {
    'AxelGard/oneokai.nvim',
    priority = 1000,
    config = function()
      require('oneokai').setup {
        style = 'darker'
      }
      vim.cmd('colorscheme oneokai')
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    end
  },

  -- OpenCode AI assistant
  {
    'NickvanDyke/opencode.nvim',
    dependencies = {
      { 'folke/snacks.nvim', opts = { input = {}, picker = {}, terminal = {} } },
    },
    config = function()
      vim.o.autoread = true
      vim.g.opencode_opts = {
        provider = {
          enabled = "tmux",
          tmux = {},
        }
      }
      local oc = require("opencode")

      -- Toggle opencode interface
      vim.keymap.set({ "n", "t" }, "<leader>oc", oc.toggle, { desc = "Toggle opencode" })

      -- Ask with context
      vim.keymap.set({ "n", "x" }, "<C-a>", function()
        oc.ask("@this: ", { submit = true })
      end, { desc = "Ask opencode" })

      -- Select menu with all actions
      vim.keymap.set({ "n", "x" }, "<C-x>", oc.select, { desc = "Opencode select menu" })

      -- Operator for adding range to prompt (supports dot-repeat)
      vim.keymap.set("n", "go", oc.operator, { desc = "Opencode operator" })
      vim.keymap.set("n", "goo", function()
        oc.operator()
        vim.api.nvim_feedkeys("_", "n", false)
      end, { desc = "Opencode current line" })
      vim.keymap.set("x", "go", function()
        oc.prompt({ submit = true })
      end, { desc = "Opencode visual selection" })
    end
  },
}
