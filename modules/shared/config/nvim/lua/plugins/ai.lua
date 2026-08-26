return {
  {
    "olimorris/codecompanion.nvim",
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    dependencies = {
      "j-hui/fidget.nvim", -- Display status
      "nvim-mini/mini.diff",
    },
    opts = {
      ---@module "codecompanion"
      ---@type CodeCompanion.Config
      adapters = {
        acp = {
          claude_code = function()
            -- Read Claude Code settings.json to get Bedrock config
            local settings_file = vim.fn.expand("~/.claude/settings.json")
            local settings = {}

            if vim.fn.filereadable(settings_file) == 1 then
              local ok, decoded = pcall(vim.fn.json_decode, vim.fn.readfile(settings_file))
              if ok and decoded.env then
                settings = decoded.env
              end
            end

            return require("codecompanion.adapters.acp").extend("claude_code", {
              commands = {
                default = {
                  "npx",
                  "--yes",
                  "@zed-industries/claude-code-acp",
                },
              },
              env = {
                -- Use AWS Bedrock (from settings.json, default off)
                CLAUDE_CODE_USE_BEDROCK = settings.CLAUDE_CODE_USE_BEDROCK or "0",
                AWS_PROFILE = settings.AWS_PROFILE or "claude",
                AWS_REGION = settings.AWS_REGION or "us-west-2",
                -- Pass through any other settings from settings.json
                ANTHROPIC_DEFAULT_SONNET_MODEL = settings.ANTHROPIC_DEFAULT_SONNET_MODEL,
                ANTHROPIC_DEFAULT_OPUS_MODEL = settings.ANTHROPIC_DEFAULT_OPUS_MODEL,
                ANTHROPIC_DEFAULT_HAIKU_MODEL = settings.ANTHROPIC_DEFAULT_HAIKU_MODEL,
              },
            })
          end,
        },
        http = {
          anthropic = function()
            return require("codecompanion.adapters.http").extend("anthropic", {
              schema = {
                extended_thinking = {
                  default = true,
                },
              },
            })
          end,

          ollama = function()
            return require("codecompanion.adapters.http").extend("ollama", {
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
      },
      interactions = {
        chat = {
          adapter = "claude_code",
        },
        inline = {
          adapter = "anthropic",
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
        log_level = "INFO",
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
      {
        "<Leader>ac",
        "<cmd>CodeCompanionChat adapter=claude_code<CR>",
        desc = "Chat with Claude Code (ACP)",
        mode = { "n", "v" },
      },
    },
    init = function()
      vim.cmd([[cab cc CodeCompanion]])
      -- require("plugins.custom.spinner"):init()
    end,
  },
}
