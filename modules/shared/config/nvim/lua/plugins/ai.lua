return {
  {
    "olimorris/codecompanion.nvim", -- The KING of AI programming
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    dependencies = {
      "j-hui/fidget.nvim", -- Display status
      -- {"ravitemer/mcphub.nvim",
      --   callback = "mcphub.extensions.codecompanion",
      --   opts = {
      --     make_vars = true,
      --     make_slash_commands = true,
      --     show_result_in_chat = true
      -- },
      -- {
      --   "Davidyz/VectorCode", -- Index and search code in your repositories
      --   version = "*",
      --   build = "pipx upgrade vectorcode",
      --   dependencies = { "nvim-lua/plenary.nvim" },
      -- },
      {
        "echasnovski/mini.diff",
        config = function()
          local diff = require("mini.diff")
          diff.setup({
            -- Disabled by default
            source = diff.gen_source.none(),
          })
        end,
      },
      -- { "echasnovski/mini.pick", config = true },
      -- { "ibhagwan/fzf-lua", config = true },
    },
    opts = {
      ---@module "codecompanion"
      ---@type CodeCompanion.Config
      adapters = {
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            -- env = {
            --   api_key = "cmd:op read op://personal/Anthropic_API/credential --no-newline",
            -- },
            schema = {
              extended_thinking = {
                default = true,
              },
            },
          })
        end,
        bedrock = function()
          return require("config.adapters.bedrock")
        end,
        ollama = function()
          return require("codecompanion.adapters").extend("ollama", {
            schema = {
              model = {
                default = "qwen3:latest",
              },
              num_ctx = {
                default = 20000,
              },
            },
          })
        end,
      },
      strategies = {
        chat = {
          -- adapter = "anthropic",
          adapter = {
            name = "anthropic",
            model = "claude-sonnet-4-20250514",
          },
          -- roles = {
          --   user = "olimorris",
          -- },
        },
        inline = {
          adapter = {
            name = "anthropic",
            -- model = "gpt-4.1",
          },
        },
      },
      display = {
        action_palette = {
          provider = "default",
          opts = {
            show_default_actions = true, -- Show the default actions in the action palette?
            show_default_prompt_library = true, -- Show the default prompt library in the action palette?
          },
        },
        chat = {
          -- show_references = true,
          -- show_header_separator = false,
          -- show_settings = false,
          auto_scroll = true,
          icons = {
            tool_success = "󰸞",
          },
        },
        diff = {
          provider = "mini_diff",
        },
      },
      opts = {
        log_level = "DEBUG",
      },
    },
    keys = {
      {
        "<C-a>",
        "<cmd>CodeCompanionActions<CR>",
        desc = "Open the action palette",
        mode = { "n", "v" },
      },
      {
        "<Leader>a",
        "<cmd>CodeCompanionChat Toggle<CR>",
        desc = "Toggle a chat buffer",
        mode = { "n", "v" },
      },
      {
        "<LocalLeader>a",
        "<cmd>CodeCompanionChat Add<CR>",
        desc = "Add code to a chat buffer",
        mode = { "v" },
      },
    },
    init = function()
      vim.cmd([[cab cc CodeCompanion]])
      -- require("plugins.custom.spinner"):init()
    end,
  },
}
