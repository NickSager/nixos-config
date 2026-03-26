return {
  -- add any tools you want to have installed below
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shfmt",
        -- "python-lsp-server",
        -- "shellcheck",
        -- "flake8",
        -- "black",
        -- "prettier"
        -- "markdown"
        -- "markdown_inline",
      },
    },
  },

  {
    "mbbill/undotree",
    lazy = false, -- needs to be explicitly set, because of the keys property
    keys = {
      {
        "<leader>U",
        vim.cmd.UndotreeToggle,
        desc = "Toggle undotree",
      },
    },
  },

  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
    },
  },

  {
    "linux-cultist/venv-selector.nvim",
    -- branch = "regexp", -- Use this branch for the new version
    dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
    opts = {
      settings = {
        options = {
          -- Your options go here
          dap_enabled = true,
          name = { "venv", ".venv", "env", ".env" },
          poetry_path = vim.fn.expand("~/.cache/pypoetry/virtualenvs"), -- Does not work. Created symlink in default directory
          -- auto_refresh = false
          -- debug = true,
        },
      },
      -- -- Your options go here
      -- dap_enabled = true,
      -- name = { "venv", ".venv", "env", ".env" },
      -- poetry_path= vim.fn.expand("~/.cache/pypoetry/virtualenvs"),
      -- -- auto_refresh = false
      -- debug = true,
    },
  },

  -- TODO: setup neotest (https://github.com/nvim-neotest/neotest)
  -- Included in lazyextras
  -- {
  -- "nvim-neotest/neotest",
  -- dependencies = {
  --   "nvim-lua/plenary.nvim",
  --   "antoinemadec/FixCursorHold.nvim",
  --   "nvim-treesitter/nvim-treesitter"
  --   }
  -- },
  --
  --
  -- {
  --   "zbirenbaum/copilot.lua",
  --   cmd = "Copilot",
  --   build = ":Copilot auth",
  --   opts = {
  --     suggestion = { enabled = true },
  --     panel = { enabled = false },
  --     filetypes = {
  --       markdown = true,
  --       help = true,
  --     },
  --   },
  -- },
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- pyright will be automatically installed with mason and loaded with lspconfig
        pyright = { enabled = true },
        -- pylsp = {},
        pylsp = {
          enabled = false,
          settings = {
            pylsp = {
              plugins = {
                -- formatter options
                black = { enabled = true },
                autopep8 = { enabled = false },
                yapf = { enabled = false },
                -- linter options
                pylint = { enabled = true, executable = "pylint" },
                pyflakes = { enabled = false },
                pycodestyle = { enabled = false },
                -- type checker
                pylsp_mypy = { enabled = true },
                -- auto-completion options
                jedi_completion = { fuzzy = true },
                -- import sorting
                pyls_isort = { enabled = true },
              },
            },
          },
        },
      },
    },
  },

  {
    "hrsh7th/nvim-cmp",
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local cmp = require("cmp")

      opts.preselect = cmp.PreselectMode.None
      opts.completion = {
        completeopt = "noselect",
      }

      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            -- You could replace select_next_item() with confirm({ select = true }) to get VS Code autocompletion behavior
            cmp.select_next_item()
          elseif vim.snippet.active({ direction = 1 }) then
            vim.schedule(function()
              vim.snippet.jump(1)
            end)
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif vim.snippet.active({ direction = -1 }) then
            vim.schedule(function()
              vim.snippet.jump(-1)
            end)
          else
            fallback()
          end
        end, { "i", "s" }),
      })

      opts.experimental = {
        ghost_text = false,
      }
    end,
  },
}
