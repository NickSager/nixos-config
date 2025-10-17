-- This is a config that can be merged with your
-- existing LazyVim config.
--
-- It configures all plugins necessary for quarto-nvim,
-- such as adding its code completion source to the
-- completion engine nvim-cmp.
-- Thus, instead of having to change your configuration entirely,
-- this takes your existings config and adds on top where necessary.

return {

  -- this taps into vim.ui.select and vim.ui.input
  -- and in doing so currently breaks renaming in otter.nvim
  { "stevearc/dressing.nvim", enabled = false },

  {
    "quarto-dev/quarto-nvim",
    opts = {
      lspFeatures = {
        languages = { "r", "python", "julia", "bash", "html", "lua" },
      },
    },
    ft = "quarto",
    keys = {
      { "<leader>Qa", ":QuartoActivate<cr>", desc = "quarto activate" },
      { "<leader>Qp", ":lua require'quarto'.quartoPreview()<cr>", desc = "quarto preview" },
      { "<leader>Qq", ":lua require'quarto'.quartoClosePreview()<cr>", desc = "quarto close" },
      { "<leader>Qh", ":QuartoHelp ", desc = "quarto help" },
      { "<leader>Qe", ":lua require'otter'.export()<cr>", desc = "quarto export" },
      { "<leader>QE", ":lua require'otter'.export(true)<cr>", desc = "quarto export overwrite" },
      { "<leader>Qrr", ":QuartoSendAbove<cr>", desc = "quarto run to cursor" },
      { "<leader>Qra", ":QuartoSendAll<cr>", desc = "quarto run all" },
      -- { "<leader><cr>", ":SlimeSend<cr>", desc = "send code chunk" },
      -- { "<c-cr>", ":SlimeSend<cr>", desc = "send code chunk" },
      { "<leader><cr>", "<Plug>SlimeSendCell<cr>", desc = "send code cell" },
      { "<c-cr>", "<Plug>SlimeSendCell<cr>", desc = "send code cell" }, -- TODO: This is not working after adding leader-cr
      -- { "<c-cr>", "<Plug>SlimeSendCell<cr>/' . vim.g.slime_cell_delimiter . <CR>:nohlsearch<CR>", desc = "send code cell" }, --TODO: debug finding next cell
      { "<c-cr>", "<esc>:SlimeSend<cr>i", mode = "i", desc = "send code chunk" },
      { "<c-cr>", "<Plug>SlimeRegionSend<cr>", mode = "v", desc = "send code chunk" },
      { "<cr>", "<Plug>SlimeRegionSend<cr>", mode = "v", desc = "send code chunk" },
      { "<leader>Qtr", ":vsplit term://R<cr>", desc = "terminal: R" },
      { "<leader>Qti", ":vsplit term://ipython<cr>", desc = "terminal: ipython" },
      { "<leader>Qtp", ":vsplit term://python<cr>", desc = "terminal: python" },
      { "<leader>Qtj", ":vsplit term://julia<cr>", desc = "terminal: julia" },
      { "<leader>Qtt", ":vsplit | terminal<cr>", desc = "terminal: terminal" },
      { "<leader>Qoo", "o# %%<cr>", desc = "new code chunk below" },
      { "<leader>QoO", "O# %%<cr>", desc = "new code chunk above" },
      { "<leader>Qob", "o```{bash}<cr>```<esc>O", desc = "bash code chunk" },
      { "<leader>Qor", "o```{r}<cr>```<esc>O", desc = "r code chunk" },
      { "<leader>Qop", "o```{python}<cr>```<esc>O", desc = "python code chunk" },
      { "<leader>Qoj", "o```{julia}<cr>```<esc>O", desc = "julia code chunk" },
    },
  },

  {
    "jmbuhr/otter.nvim",
    opts = {
      buffers = {
        set_filetype = true,
        write_to_disk = true,
      },
    },
  },

  {
    "hrsh7th/nvim-cmp",
    dependencies = { "jmbuhr/otter.nvim" },
    opts = function(_, opts)
      ---@param opts cmp.ConfigSchema
      local cmp = require("cmp")
      opts.sources = cmp.config.sources(vim.list_extend(opts.sources, { { name = "otter" } }))
    end,
  },

  -- send code from python/r/qmd documets to a terminal or REPL
  -- like ipython, R, bash
  {
    "jpalardy/vim-slime",
    init = function()
      vim.b["quarto_is_" .. "python" .. "_chunk"] = false
      Quarto_is_in_python_chunk = function()
        require("otter.tools.functions").is_otter_language_context("python")
      end

      vim.cmd([[
      let g:slime_dispatch_ipython_pause = 100
      function SlimeOverride_EscapeText_quarto(text)
      call v:lua.Quarto_is_in_python_chunk()
      if exists('g:slime_python_ipython') && len(split(a:text,"\n")) > 1 && b:quarto_is_python_chunk
      return ["%cpaste -q\n", g:slime_dispatch_ipython_pause, a:text, "--", "\n"]
      " return [g:slime_dispatch_ipython_pause, a:text, "\n"]
      else
      return a:text
      end
      endfunction
      ]])

      local function mark_terminal()
        vim.g.slime_last_channel = vim.b.terminal_job_id
        vim.print(vim.g.slime_last_channel)
      end

      local function set_terminal()
        vim.b.slime_config = { jobid = vim.g.slime_last_channel }
      end

      -- slime, neovvim terminal
      -- vim.g.slime_target = "tmux"
      vim.g.slime_cell_delimiter = "# %%" -- use :SlimeSendCell
      vim.g.slime_target = "neovim"
      vim.g.slime_python_ipython = 1
      vim.g.slime_bracketed_paste = 1

      -- require("which-key").register({
      --   ["<leader>Qtm"] = { mark_terminal, "mark terminal" },
      --   ["<leader>Qts"] = { set_terminal, "set terminal" },
      -- })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- pyright = {},
        r_language_server = {},
        julials = {},
        marksman = {
          -- also needs:
          -- $home/.config/marksman/config.toml :
          -- [core]
          -- markdown.file_extensions = ["md", "markdown", "qmd"]
          filetypes = { "markdown", "quarto" },
          root_dir = require("lspconfig.util").root_pattern(".git", ".marksman.toml", "_quarto.yml"),
        },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "html",
        "javascript",
        "json",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
        "bash",
        "html",
        "css",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "vim",
        "yaml",
        "python",
        "julia",
        "r",
      },
    },
  },
}
