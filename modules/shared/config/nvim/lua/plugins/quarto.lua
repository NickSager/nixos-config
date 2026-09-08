return {
  {
    "quarto-dev/quarto-nvim",
    ft = "quarto",
    dependencies = {
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
        "jpalardy/vim-slime",
        init = function()
          vim.b.quarto_is_python_chunk = false
          Quarto_is_in_python_chunk = function()
            require("otter.tools.functions").is_otter_language_context("python")
          end
          vim.cmd([[
            function SlimeOverride_EscapeText_quarto(text)
              call v:lua.Quarto_is_in_python_chunk()
              if exists('g:slime_python_ipython') && len(split(a:text,"\n")) > 1 && b:quarto_is_python_chunk
                return ["%cpaste -q\n", g:slime_dispatch_ipython_pause, a:text, "--", "\n"]
              end
              return a:text
            endfunction
          ]])
          vim.g.slime_dispatch_ipython_pause = 100
          vim.g.slime_cell_delimiter = "# %%"
          vim.g.slime_target = "neovim"
          vim.g.slime_python_ipython = 1
          vim.g.slime_bracketed_paste = 1
        end,
      },
    },
    opts = {
      lspFeatures = {
        languages = { "r", "python", "julia", "bash", "html", "lua" },
      },
    },
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

}
