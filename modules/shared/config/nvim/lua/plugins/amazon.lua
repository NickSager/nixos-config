-- Method 1: ---------------
return {

    -- Use `bemol --watch --verbose` to run LSP
    {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    setup = {
      handlers = {
        -- function(server_name)
        --   local server = servers[server_name] or {}
        --   require("lspconfig")[server_name].setup({
        --     cmd = server.cmd,
        --     settings = server.settings,
        --     filetypes = server.filetypes,
        --     capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {}),
        --   })
        -- end,
        jdtls = function()
          require("lspconfig").jdtls.setup({
            on_attach = function()
              local bemol_dir = vim.fs.find({ ".bemol" }, { upward = true, type = "directory" })[1]
              local ws_folders_lsp = {}
              if bemol_dir then
                local file = io.open(bemol_dir .. "/ws_root_folders", "r")
                if file then
                  for line in file:lines() do
                    table.insert(ws_folders_lsp, line)
                  end
                  file:close()
                end
              end
              for _, line in ipairs(ws_folders_lsp) do
                vim.lsp.buf.add_workspace_folder(line)
              end
            end,
            cmd = {
              "jdtls",
              '-javaagent:' .. vim.fn.expand("$MASON/packages/jdtls/lombok.jar"),
              -- "--jvm-arg=-javaagent:" .. require("mason-registry")
              --   .get_package("jdtls")
              --   :get_install_path() .. "/lombok.jar",
            },
          })
        end,
      },
    },
  },

  -- Barium
  {
    url = "ssh://git.amazon.com/pkg/NinjaHooks",
    branch = "mainline",
    -- This magic setup is copied from https://github.com/folke/lazy.nvim/issues/183#issuecomment-1376469054
    ft = "brazil-config",
    config = function(plugin)
      vim.opt.rtp:prepend(plugin.dir .. "/configuration/vim/amazon/brazil-config")
      require("lazy.core.loader").packadd(plugin.dir .. "/configuration/vim/amazon/brazil-config")
    end,
    init = function(plugin)
      require("lazy.core.loader").ftdetect(plugin.dir .. "/configuration/vim/amazon/brazil-config")
    end,
  },

  -- Amazon Q Developer
  -- {
  --   name = 'amazonq',
  --   url = 'ssh://git.amazon.com/pkg/AmazonQNVim',
  --   opts = {
  --     ssoStartUrl = 'https://amzn.awsapps.com/start',
  --     -- Note: It's normally not necessary to change default `lsp_server_cmd`.
  --     -- lsp_server_cmd = {
  --     --   'node',
  --     --   vim.fn.stdpath('data') .. '/lazy/AmazonQNVim/language-server/build/aws-lsp-codewhisperer-token-binary.js',
  --     --   '--stdio',
  --     -- },
  --   },
  -- },

}


-- Method 2: -------------

-- require("nvim-lspconfig").setup({
-- 	handlers = {
-- 		function(server_name)
-- 			local server = servers[server_name] or {}
-- 			require("lspconfig")[server_name].setup({
-- 				cmd = server.cmd,
-- 				settings = server.settings,
-- 				filetypes = server.filetypes,
-- 				capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {}),
-- 			})
-- 		end,
-- 		jdtls = function()
-- 			require("lspconfig").jdtls.setup({
-- 				on_attach = function()
-- 					local bemol_dir = vim.fs.find({ ".bemol" }, { upward = true, type = "directory" })[1]
-- 					local ws_folders_lsp = {}
-- 					if bemol_dir then
-- 						local file = io.open(bemol_dir .. "/ws_root_folders", "r")
-- 						if file then
-- 							for line in file:lines() do
-- 								table.insert(ws_folders_lsp, line)
-- 							end
-- 							file:close()
-- 						end
-- 					end
-- 					for _, line in ipairs(ws_folders_lsp) do
-- 						vim.lsp.buf.add_workspace_folder(line)
-- 					end
-- 				end,
-- 				cmd = {
-- 					"jdtls",
-- 					"--jvm-arg=-javaagent:" .. require("mason-registry")
-- 						.get_package("jdtls")
-- 						:get_install_path() .. "/lombok.jar",
-- 				},
-- 			})
-- 		end,
-- 	},
-- })


-- Method 3: -------------

-- return {
--   "mfussenegger/nvim-jdtls",
--   opts = function(_, opts)
--     local root_dir = require("jdtls.setup").find_root({ "packageInfo" }, "Config")
--
--     local workspaces = {}
--     if root_dir then
--       local file = io.open(root_dir .. "/.bemol/ws_root_folders")
--       if file then
--         for line in file:lines() do
--           table.insert(workspaces, "file://" .. line)
--         end
--         file:close()
--       end
--     end
--     for _, line in ipairs(workspaces) do
--       vim.lsp.buf.add_workspace_folder(line)
--     end
--
--     local project_name = opts.project_name(root_dir)
--     local cmd = vim.deepcopy(opts.cmd)
--     if project_name then
--       vim.list_extend(cmd, {
--         "-configuration",
--         opts.jdtls_config_dir(project_name),
--         "-data",
--         opts.jdtls_workspace_dir(project_name),
--       })
--     end
--
--     opts.jdtls = {
--       cmd = cmd,
--       init_options = {
--         workspaceFolders = workspaces,
--       },
--       root_dir = root_dir,
--     }
--   end,
-- }


-- ~/.config/nvim/ftplugin/java.lua
-- helper function for checking if a table contains a value
-- local function contains(table, value)
--     for _, table_value in ipairs(table) do
--         if table_value == value then
--             return true
--         end
--     end
--
--     return false
-- end
--
-- -- helper function for finding a filename in a directory which matches
-- -- the specified pattern
-- local function find_file(directory, pattern)
--     local filename_found = ''
--     local pfile = io.popen('ls "' .. directory .. '"')
--
--     if (pfile == nil) then
--         return ''
--     end
--
--     for filename in pfile:lines() do
--         if (string.find(filename, pattern) ~= nil) then
--             filename_found = filename
--             break
--         end
--     end
--
--     return filename_found
-- end
--
-- -- gathers all of the bemol-generated files and adds them to the LSP workspace
-- local function bemol()
--     local bemol_dir = vim.fs.find({ ".bemol" }, { upward = true, type = "directory" })[1]
--     local ws_folders_lsp = {}
--     if bemol_dir then
--         local file = io.open(bemol_dir .. "/ws_root_folders", "r")
--         if file then
--             for line in file:lines() do
--                 table.insert(ws_folders_lsp, line)
--             end
--             file:close()
--         end
--
--         for _, line in ipairs(ws_folders_lsp) do
--             if not contains(vim.lsp.buf.list_workspace_folders(), line) then
--                 vim.lsp.buf.add_workspace_folder(line)
--             end
--         end
--     end
-- end
--
-- local jdtls = require "jdtls"
-- local jdtls_setup = require "jdtls.setup"
--
-- local home = os.getenv("HOME")
-- local root_markers = { ".bemol", }
-- local root_dir = jdtls_setup.find_root(root_markers)
-- local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
-- local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name
-- local path_to_mason_packages = home .."/.local/share/nvim/mason/packages"
-- local path_to_jdtls_temp = path_to_mason_packages .. "/jdtls"
-- local path_to_jdtls = io.popen('readlink -f "' .. vim.fn.expand(path_to_jdtls_temp) .. '"') -- For nix management
-- local os_type = vim.fn.has("macunix") and "mac" or "linux"
-- local path_to_config = path_to_jdtls .. "/config_" .. os_type
-- local path_to_lombok = path_to_jdtls .. "/lombok.jar"
-- local path_to_plugins = path_to_jdtls .. "/plugins/"
-- -- the eclipse jar is suffixed with a bunch of version nonsense, so we find it by pattern matching
-- local path_to_jar = path_to_plugins .. find_file(path_to_plugins, "org.eclipse.equinox.launcher_")
--
-- local config = {
--     cmd = {
--         -- assumes the java binary is in your PATH and at least java17;
--         -- if not, specify the full path to the binary
--         "java",
--         "-Declipse.application=org.eclipse.jdt.ls.core.id1",
--         "-Dosgi.bundles.defaultStartLevel=4",
--         "-Declipse.product=org.eclipse.jdt.ls.core.product",
--         "-Dlog.protocol=true",
--         "-Dlog.level=ALL",
--         "-Xmx1g",
--         "-javaagent:" .. path_to_lombok,
--         "--add-modules=ALL-SYSTEM",
--         "--add-opens",
--         "java.base/java.util=ALL-UNNAMED",
--         "--add-opens",
--         "java.base/java.lang=ALL-UNNAMED",
--
--         "-jar",
--         path_to_jar,
--
--         "-configuration",
--         path_to_config,
--
--         "-data",
--         workspace_dir,
--     },
--
--     root_dir = root_dir,
--
--     capabilities = {
--         workspace = {
--             configuration = true
--         },
--         textDocument = {
--             completion = {
--                 completionItem = {
--                     snippetSupport = true
--                 }
--             }
--         }
--     },
--
--     settings = {
--         java = {
--             references = {
--                 includeDecompiledSources = true,
--             },
--             eclipse = {
--                 downloadSources = true,
--             },
--             maven = {
--                 downloadSources = true,
--             },
--             sources = {
--                 organizeImports = {
--                     starThreshold = 9999,
--                     staticStarThreshold = 9999,
--                 },
--             },
--         }
--     },
--
--     -- run our bemol function when the LSP attaches to the buffer
--     on_attach = bemol,
-- }
--
-- jdtls.start_or_attach(config)
