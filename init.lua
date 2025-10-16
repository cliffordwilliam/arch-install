-- ~/.config/nvim/init.lua
-- Minimal Neovim IDE Configuration

-- Set leader key to space (like VSCode's Ctrl+Shift+P)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic settings
vim.opt.clipboard = "unnamedplus"    -- Yank to system with xclip installed
vim.opt.number = true                -- Show line numbers
vim.opt.ignorecase = true            -- Ignore case in search
vim.opt.smartcase = true             -- Unless uppercase is used
vim.opt.hlsearch = false             -- Don't highlight searches
vim.opt.wrap = false                 -- No line wrap
vim.opt.breakindent = true           -- Preserve indent on wrap
vim.opt.tabstop = 4                  -- Tab width
vim.opt.shiftwidth = 4               -- Indent width
vim.opt.expandtab = true             -- Use spaces instead of tabs
vim.opt.termguicolors = true         -- True color support
vim.opt.signcolumn = "yes"           -- Always show sign column

-- Bootstrap lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin specifications
require("lazy").setup({
  -- Color scheme
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme nightfox]])
    end,
  },

  -- Fuzzy finder (like VSCode's Ctrl+P)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup()
    end,
  },

  -- Syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "python", "bash" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- LSP Configuration (using built-in vim.lsp.config for Neovim 0.11+)
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Setup Python LSP using new vim.lsp.config API
      vim.lsp.config.pylsp = {
        cmd = { "pylsp" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "setup.py", ".git" },
      }
      
      -- Enable LSP for Python files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function()
          vim.lsp.enable("pylsp")
        end,
      })
      
      -- Key mappings for LSP
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        end,
      })
    end,
  },

  -- Auto-completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },
})

-- Key mappings (similar to VSCode shortcuts)
vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>", { desc = "Live grep" })
