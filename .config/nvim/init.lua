local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
-- vim.lsp.set_log_level("TRACE")

local icons = {
  diagnostics = {
    Error = " ",
    Warn = " ",
    Hint = " ",
    Info = " ",
  },
  git = {
    added = " ",
    modified = " ",
    removed = " ",
  },
  kinds = {
    Array = " ",
    Boolean = " ",
    Class = " ",
    Color = " ",
    Constant = " ",
    Constructor = " ",
    Copilot = " ",
    Enum = " ",
    EnumMember = " ",
    Event = " ",
    Field = " ",
    File = " ",
    Folder = " ",
    Function = " ",
    Interface = " ",
    Key = " ",
    Keyword = " ",
    Method = " ",
    Module = " ",
    Namespace = " ",
    Null = " ",
    Number = " ",
    Object = " ",
    Operator = " ",
    Package = " ",
    Property = " ",
    Reference = " ",
    Snippet = " ",
    String = " ",
    Struct = " ",
    Text = " ",
    TypeParameter = " ",
    Unit = " ",
    Value = " ",
    Variable = " ",
  },
}
local home_dir = os.getenv("HOME")
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local jdtls_workspace_dir = home_dir .. "/.cache/jdtls-workspaces-1.21.0/" .. project_name

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("lazy").setup({
  -- ----------------------------------------------------------------------------------------------
  -- #Utility
  -- Measure startup time.
  {
    "dstein64/vim-startuptime",
    cmd = "StartupTime",
    config = function()
      vim.g.startuptime_tries = 10
    end,
  },
  -- Shared library used by multiple plugins.
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
  -- Makes some plugins dot-repeatable, like leap.
  {
    "tpope/vim-repeat",
    event = "VeryLazy",
  },
  -- Allow text to be copied to local clipboard over SSH.
  {
    "ojroques/nvim-osc52",
    event = "VeryLazy",
    config = function()
      vim.keymap.set("n", "<leader>y", require("osc52").copy_operator, {expr = true, desc = "Copy to local clipboard"})
      vim.keymap.set("v", "<leader>y", require("osc52").copy_visual, {desc = "Copy to local clipboard"})
    end,
  },
  -- ----------------------------------------------------------------------------------------------
  -- #Colorscheme
  {
    "rebelot/kanagawa.nvim",
    config = function()
      vim.cmd("colorscheme kanagawa")
    end,
  },
  {
    "Glench/Vim-Jinja2-Syntax",
  },
  -- ----------------------------------------------------------------------------------------------
  -- #LSP
  {
    "neovim/nvim-lspconfig",
    event = {"BufReadPre", "BufNewFile"},
    dependencies = {
      {
        "folke/neodev.nvim",
        opts = {
          experimental = {pathStrict = true},
        },
      },
      "mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    opts = {
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {spacing = 4, prefix = "●"},
        severity_sort = true,
      },
      -- options for vim.lsp.buf.format
      -- `bufnr` and `filter` is handled by the LazyVim formatter,
      -- but can be also overridden when specified
      format = {
        formatting_options = nil,
        timeout_ms = nil,
      },
      -- LSP Server Settings
      servers = {
        jsonls = {},
        lua_ls = {
          -- mason = false, -- set to false if you don't want this server to be installed with mason
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
              completion = {
                callSnippet = "Replace",
              },
            },
          },
        },
        -- tsserver = {
        --   settings = {
        --     diagnostics = {
        --       -- https://github.com/microsoft/TypeScript/blob/main/src/compiler/diagnosticMessages.json
        --       ignoredCodes = {
        --         80006,
        --       },
        --     },
        --   },
        -- },
        eslint = {
          filetypes = {"javascript", "javascriptreact"},
        },
        jdtls = {
          cmd = {
            "java",
            "-Declipse.application=org.eclipse.jdt.ls.core.id1",
            "-Dosgi.bundles.defaultStartLevel=4",
            "-Declipse.product=org.eclipse.jdt.ls.core.product",
            "-Dlog.protocol=true",
            "-Dlog.level=ALL",
            "-Xms1g",
            "--add-modules=ALL-SYSTEM",
            "--add-opens",
            "java.base/java.util=ALL-UNNAMED",
            "--add-opens",
            "java.base/java.lang=ALL-UNNAMED",
            "-jar",
            home_dir .. "/.config/jdtls-1.21.0/plugins/org.eclipse.equinox.launcher_1.6.400.v20210924-0641.jar",
            "-configuration",
            home_dir .. "/.config/jdtls-1.21.0/config_linux",
            "-data",
            jdtls_workspace_dir,
          },
          settings = {
            java = {
              project = {
                referencedLibraries = {
                  "lib/**/*.jar",
                  "ivylib/**/*.jar",
                  "main/bin/**/*.jar",
                  "test/bin/**/*.jar",
                  "bin/**/*.jar",
                },
                sourcePaths = {
                  "main",
                  "test",
                  "shared",
                },
              },
              -- maxConcurrentBuilds = 5,
            },
          },
        },
        -- pyright = {},
        rust_analyzer = {},
      },
      -- you can do any additional lsp server setup here
      -- return true if you don't want this server to be setup with lspconfig
      setup = {
        -- example to setup with typescript.nvim
        -- tsserver = function(_, opts)
        --   require("typescript").setup({ server = opts })
        --   return true
        -- end,
        -- Specify * to use this function as a fallback for any server
        -- ["*"] = function(server, opts) end,
      },
    },
    config = function(_, opts)
      -- Keymaps
      local function diagnostic_goto(next, severity)
          local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
          severity = severity and vim.diagnostic.severity[severity] or nil
          return function()
            go({severity = severity})
          end
      end
      local keymap = {
        {"<leader>cd", vim.diagnostic.open_float, desc = "Line diagnostics"},
        {"<leader>cl", "<cmd>LspInfo<cr>", desc = "Lsp info"},
        {"gd", "<cmd>Telescope lsp_definitions<cr>", desc = "Goto definition", has = "definition"},
        {"gr", "<cmd>Telescope lsp_references show_line=false<cr>", desc = "References"},
        {"gD", vim.lsp.buf.declaration, desc = "Goto declaration"},
        {"gI", "<cmd>Telescope lsp_implementations<cr>", desc = "Goto implementation"},
        {"gt", "<cmd>Telescope lsp_type_definitions<cr>", desc = "Goto type definition"},
        {"K", vim.lsp.buf.hover, desc = "Hover"},
        {"<C-n>", diagnostic_goto(true), desc = "Next diagnostic"},
        {"<C-b>", diagnostic_goto(false), desc = "Prev diagnostic"},
        {"<C-e>", diagnostic_goto(true, "ERROR"), desc = "Next error"},
        {"<C-S-e>", diagnostic_goto(false, "ERROR"), desc = "Prev error"},
        {"<C-q>", diagnostic_goto(true, "WARN"), desc = "Next warning"},
        {"<C-S-q>", diagnostic_goto(false, "WARN"), desc = "Prev warning"},
        {"<leader>rn", vim.lsp.buf.rename, desc = "Rename token"},
        {"<leader>ca", vim.lsp.buf.code_action, desc = "Code action", mode = { "n", "v" }, has = "codeAction"},
        {
          "<leader>cA",
          function()
            vim.lsp.buf.code_action({
              context = {
                only = {
                  "source",
                },
                diagnostics = {},
              },
            })
          end,
          desc = "Source action",
          has = "codeAction",
        }
      }
      local function keymap_on_attach(client, buffer)
        local Keys = require("lazy.core.handler.keys")
        -- local keymaps = {}
        --
        -- for _, value in ipairs(keymap) do
        --   local keys = Keys.parse(value)
        --   if keys[2] == vim.NIL or keys[2] == false then
        --     keymaps[keys.id] = nil
        --   else
        --     keymaps[keys.id] = keys
        --   end
        -- end

        for _, keys in pairs(keymap) do
          if not keys.has or client.server_capabilities[keys.has .. "Provider"] then
            if keys[1] == "<C-S-n>" then
            end
            local keyOpts = Keys.opts(keys)
            ---@diagnostic disable-next-line: no-unknown
            keyOpts.has = nil
            keyOpts.silent = opts.silent ~= false
            keyOpts.buffer = buffer
            vim.keymap.set(keys.mode or "n", keys[1], keys[2], keyOpts)
          end
        end
      end

      -- setup autoformat
      -- require("lazyvim.plugins.lsp.format").autoformat = opts.autoformat

      -- -- setup formatting and keymaps
      -- require("lazyvim.util").on_attach(function(client, buffer)
      --   require("lazyvim.plugins.lsp.format").on_attach(client, buffer)
      --   require("lazyvim.plugins.lsp.keymaps").on_attach(client, buffer)
      -- end)

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local buffer = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          keymap_on_attach(client, buffer)
        end,
      })

      -- diagnostics
      for name, icon in pairs(icons.diagnostics) do
        name = "DiagnosticSign" .. name
        vim.fn.sign_define(name, {text = icon, texthl = name, numhl = ""})
      end
      vim.diagnostic.config(opts.diagnostics)

      local servers = opts.servers
      local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

      local function setup(server)
        local server_opts = vim.tbl_deep_extend("force", {
          capabilities = vim.deepcopy(capabilities),
        }, servers[server] or {})

        if opts.setup[server] then
          if opts.setup[server](server, server_opts) then
            return
          end
        elseif opts.setup["*"] then
          if opts.setup["*"](server, server_opts) then
            return
          end
        end
        require("lspconfig")[server].setup(server_opts)
      end

      -- get all the servers that are available through mason-lspconfig
      local have_mason, mlsp = pcall(require, "mason-lspconfig")
      local all_mslp_servers = {}
      if have_mason then
        all_mslp_servers = vim.tbl_keys(require("mason-lspconfig.mappings.server").lspconfig_to_package)
      end

      local ensure_installed = {}
      for server, server_opts in pairs(servers) do
        if server_opts then
          server_opts = server_opts == true and {} or server_opts
          -- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
          if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
            setup(server)
          else
            ensure_installed[#ensure_installed + 1] = server
          end
        end
      end

      if have_mason then
        mlsp.setup({ensure_installed = ensure_installed})
        mlsp.setup_handlers({setup})
      end
    end,
  },
  -- formatters
  --[[ {
    "pmizio/typescript-tools.nvim",
    dependencies = {"nvim-lua/plenary.nvim", "neovim/nvim-lspconfig"},
    config = function(_, opts)
      local api = require("typescript-tools.api")
      require("typescript-tools").setup({
        settings = {
          tsserver_format_options = {
            insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = false,
          },
        },
        handlers = {
          ["textDocument/publishDiagnostics"] = api.filter_diagnostics(
            -- https://github.com/microsoft/TypeScript/blob/main/src/compiler/diagnosticMessages.json
            {80006}
          ),
        },
      })
    end,
  }, ]]
  -- cmdline tools and lsp servers
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = {
      {"<leader>cm", "<cmd>Mason<cr>", desc = "Mason"}
    },
    opts = {
      ensure_installed = {
        "stylua",
        "shfmt",
        -- "flake8",
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      local function ensure_installed()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end
      if mr.refresh then
        mr.refresh(ensure_installed)
      else
        ensure_installed()
      end
    end,
  },
  -- ----------------------------------------------------------------------------------------------
  -- #Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    event = {"BufReadPost", "BufNewFile"},
    config = function()
      require("nvim-treesitter.configs").setup({
        ignore_install = {"help"},
        ensure_installed = "all",
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
          disable = {"ruby"},
        },
        context_commentstring = {
          enable = true,
        },
        folds = {
          enable = false,
        },
        injections = {
          enable = false,
        },
        playground = {
          enable = true,
        },
      })
    end,
  },
  {
    "nvim-treesitter/playground",
  },
  -- ----------------------------------------------------------------------------------------------
  -- #Editor
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    version = false,
    config = function()
      local fb_actions = require("telescope").extensions.file_browser.actions;
      require("telescope").setup({
        extensions = {
          fzf = {
            fuzzy = false,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
          file_browser = {
            hidden = true, -- show hidden files
            path = "%:p:h", -- open file browser in current buffer dir
            file_ignore_patterns = {".git/"}, -- ignore .git dir
            layout_strategy = "flex",
            mappings = {
              ["n"] = {
                r = false,
                rn = fb_actions.rename,
                ["<bs>"] = false,
              },
            },
          },
        },
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          layout_strategy = "flex",
          layout_config = {
            flex = {
              flip_columns = 130,
              horizontal = {
                preview_width = 0.5,
              },
              vertical = {
                preview_height =  0.3,
              },
            },
          },
          cache_picker = {
            num_pickers = 20,
          },
          mappings = {
            n = {
              ["q"] = function(...)
                return require("telescope.actions").close(...)
              end,
            },
          },
          preview = {
            filesize_limit = 2, -- 2MB
            timeout = 200, -- 200ms
            tresitter = false, -- no treesitter highlighting (it's slow)
          },
        },
      })
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("file_browser")
    end,
    -- opts = {
    --   extensions = {
    --     fzf = {
    --       fuzzy = false,
    --       override_generic_sorter = true,
    --       override_file_sorter = true,
    --       case_mode = "smart_case",
    --     },
    --     file_browser = {
    --       hidden = true, -- show hidden files
    --       path = "%:p:h", -- open file browser in current buffer dir
    --       file_ignore_patterns = {".git/"}, -- ignore .git dir
    --       layout_strategy = "flex",
    --       mappings = {
    --         ["n"] = {
    --           r = false,
    --           rn = require("telescope.extensions.file_browser.actions").rename,
    --           ["<bs>"] = false,
    --         },
    --       },
    --     },
    --   },
    --   defaults = {
    --     prompt_prefix = " ",
    --     selection_caret = " ",
    --     layout_strategy = "flex",
    --     layout_config = {
    --       flex = {
    --         flip_columns = 130,
    --         horizontal = {
    --           preview_width = 0.5,
    --         },
    --         vertical = {
    --           preview_height =  0.3,
    --         },
    --       },
    --     },
    --     cache_picker = {
    --       num_pickers = 20,
    --     },
    --     mappings = {
    --       n = {
    --         ["q"] = function(...)
    --           return require("telescope.actions").close(...)
    --         end,
    --       },
    --     },
    --     preview = {
    --       filesize_limit = 2, -- 2MB
    --       timeout = 200, -- 200ms
    --       tresitter = false, -- no treesitter highlighting (it's slow)
    --     },
    --   },
    -- },
    keys = function()
      local function get_root()
        local root_patterns = { ".git", "lua" }
        ---@type string?
        local path = vim.api.nvim_buf_get_name(0)
        path = path ~= "" and vim.loop.fs_realpath(path) or nil
        ---@type string[]
        local roots = {}
        if path then
          for _, client in pairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
            local workspace = client.config.workspace_folders
            local paths = workspace and vim.tbl_map(function(ws)
              return vim.uri_to_fname(ws.uri)
            end, workspace) or client.config.root_dir and { client.config.root_dir } or {}
            for _, p in ipairs(paths) do
              local r = vim.loop.fs_realpath(p)
              if path:find(r, 1, true) then
                roots[#roots + 1] = r
              end
            end
          end
        end
        table.sort(roots, function(a, b)
          return #a > #b
        end)
        ---@type string?
        local root = roots[1]
        if not root then
          path = path and vim.fs.dirname(path) or vim.loop.cwd()
          ---@type string?
          root = vim.fs.find(root_patterns, { path = path, upward = true })[1]
          root = root and vim.fs.dirname(root) or vim.loop.cwd()
        end
        ---@cast root string
        return root
      end
      local function telescope_fn(builtin, opts)
        local params = { builtin = builtin, opts = opts }
        return function()
          builtin = params.builtin
          opts = params.opts
          opts = vim.tbl_deep_extend("force", { cwd = get_root() }, opts or {})
          if builtin == "files" then
            if vim.loop.fs_stat((opts.cwd or vim.loop.cwd()) .. "/.git") then
              opts.show_untracked = true
              builtin = "git_files"
            else
              builtin = "find_files"
            end
          end
          require("telescope.builtin")[builtin](opts)
        end
      end
      return {
        {
          "<leader>ff",
          telescope_fn("files", {cwd = false}),
          desc = "Find files (root)",
        },
        {
          "<leader>fF",
          telescope_fn("files"),
          desc = "Find files (cwd)",
        },
        {
          "<leader>fg",
          telescope_fn("live_grep"),
          desc = "Find in files (grep)",
        },
        {
          "<leader>fd",
          "<cmd>Telescope file_browser<cr>",
          desc = "File browser",
        },
        {
          "<leader>fs",
          "<cmd>Telescope buffers<cr>",
          desc = "Buffers",
        },
        {
          "<leader>fa",
          "<cmd>Telescope pickers<cr>",
          desc = "Pickers",
        },
      }
    end,
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    -- config = function()
    --   require("telescope").load_extension("fzf")
    -- end,
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    -- config = function()
    --   require("telescope").load_extension("file_browser")
    -- end,
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        search = {
          enabled = false,
        },
      },
    },
    keys = {
      {
        "s",
        mode = {"n", "x", "o"},
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "S",
        mode = {"n", "x", "o"},
        function()
          require("flash").treesitter()
        end,
        desc = "Flash treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    cmd = {"TodoTrouble", "TodoTelescope"},
    event = {"BufReadPost", "BufNewFile"},
    config = true,
    -- stylua: ignore
    keys = {
      {"<C-t>", function() require("todo-comments").jump_next() end, desc = "Next todo comment"},
      {"<C-S-t>", function() require("todo-comments").jump_prev() end, desc = "Previous todo comment"},
      {"<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo"},
    },
  },
  -- ----------------------------------------------------------------------------------------------
  -- #Coding
  -- Fix indentation based on file context.
  {
    "nmac427/guess-indent.nvim",
    config = function()
      require("guess-indent").setup({})
    end,
  },
  -- Comments
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
  },
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup({
        toggler = {
          line = "rr",
          block = nil,
        },
        opleader = {
          line = "r",
          block = "R",
        },
        mappings = {
          extra = false,
        },
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
      })
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    build = (not jit.os:find("Windows"))
        and "echo -e 'NOTE: jsregexp is optional, so not a big deal if it fails to build\n'; make install_jsregexp"
      or nil,
    dependencies = {
      "rafamadriz/friendly-snippets",
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
      end,
    },
    keys = function()
      -- Disable keymap so we can set up supertab in nvim-cmp
      ---@type string[]
      return {}
    end,
    opts = {
      history = true,
      region_check_events = "CursorMoved",
      delete_check_events = "TextChanged",
    },
  },
  {
    "hrsh7th/nvim-cmp",
    version = false,
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
    },
    opts = function()
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end
      local luasnip = require("luasnip")
      local cmp = require("cmp")
      return {
        -- Disable first option being automatically selected.
        preselect = cmp.PreselectMode.None,
        completion = {
          completeopt = "menu,menuone,noselect"
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = {
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<C-CR>"] = cmp.mapping.confirm({select = true}),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        },
        sources = cmp.config.sources({
          {name = "nvim_lsp"},
          {name = "luasnip"},
          {name = "buffer"},
          {name = "path"},
        }),
        formatting = {
          format = function(_, item)
            local icons = icons.kinds
            if icons[item.kind] then
              item.kind = icons[item.kind] .. item.kind
            end
            return item
          end,
        },
        experimental = {
          ghost_text = {
            hl_group = "LspCodeLens",
          },
        },
      }
    end,
  },
  -- Splitjoin
  {
    "Wansmer/treesj",
    dependencies = {"nvim-treesitter/nvim-treesitter"},
    config = function()
      local lang_utils = require("treesj.langs.utils")
      local no_bracket_space_config = {
        object = lang_utils.set_preset_for_dict({
          join = {
            space_in_brackets = false,
          },
        }),
        array = lang_utils.set_preset_for_list({
          join = {
            space_in_brackets = false,
          },
        }),
      }
      require("treesj").setup({
        use_default_keymaps = false,
        langs = {
          tsx = no_bracket_space_config,
          typescript = no_bracket_space_config,
        },
      })
      vim.keymap.set("n", "<leader>j", "<cmd>lua require('treesj').toggle()<cr>", {desc = "Split join"})
    end,
  },
  -- {
  --   "echasnovski/mini.ai",
  --   version = false,
  --   config = function()
  --     require("mini.ai").setup()
  --   end,
  -- },
  -- {
  --   "nvim-treesitter/nvim-treesitter-textobjects",
  --   dependencies = {"nvim-treesitter/nvim-treesitter"},
  -- },
  -- ----------------------------------------------------------------------------------------------
  -- #UI
  {
    "stevearc/dressing.nvim",
    lazy = true,
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.select(...)
      end
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.input = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.input(...)
      end
    end,
    opts = {
      input = {
        -- Prefer wider windows for input.
        prefer_width = 0.9,
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      -- local icons = require("lazyvim.config").icons

      local function fg(name)
        return function()
          ---@type {foreground?:number}?
          local hl = vim.api.nvim_get_hl_by_name(name, true)
          return hl and hl.foreground and { fg = string.format("#%06x", hl.foreground) }
        end
      end

      return {
        options = {
          theme = "auto",
          globalstatus = true,
          disabled_filetypes = {statusline = {"dashboard", "alpha"}},
        },
        sections = {
          lualine_a = {"mode"},
          lualine_b = {"branch"},
          lualine_c = {
            {
              "diagnostics",
              symbols = {
                error = icons.diagnostics.Error,
                warn = icons.diagnostics.Warn,
                info = icons.diagnostics.Info,
                hint = icons.diagnostics.Hint,
              },
            },
            {"filetype", icon_only = true, separator = "", padding = {left = 1, right = 0}},
            {"filename", path = 0, symbols = {modified = "  ", readonly = "", unnamed = ""}},
          },
          lualine_x = {
            {require("lazy.status").updates, cond = require("lazy.status").has_updates, color = fg("Special")},
            {
              "diff",
              symbols = {
                added = icons.git.added,
                modified = icons.git.modified,
                removed = icons.git.removed,
              },
            },
          },
          lualine_y = {},
          lualine_z = {
            {"progress", separator = " ", padding = {left = 1, right = 0}},
            {"location", padding = {left = 0, right = 1}},
          },
        },
        extensions = {"lazy"},
      }
    end,
  },
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = {"BufReadPost", "BufNewFile"},
    opts = {
      -- char = "▏",
      char = "│",
      filetype_exclude = {"help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy"},
      show_trailing_blankline_indent = false,
      show_current_context = false,
    },
  },
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    opts = function()
      local dashboard = require("alpha.themes.dashboard")
      local logo = [[
      ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          Z
      ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      Z    
      ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   z       
      ██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║ z         
      ███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║
      ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝
      ]]

      dashboard.section.header.val = vim.split(logo, "\n")
      dashboard.section.buttons.val = {
        dashboard.button("f", " " .. " Find file", ":Telescope find_files <CR>"),
        dashboard.button("n", " " .. " New file", ":ene <BAR> startinsert <CR>"),
        dashboard.button("r", " " .. " Recent files", ":Telescope oldfiles <CR>"),
        dashboard.button("g", " " .. " Find text", ":Telescope live_grep <CR>"),
        dashboard.button("c", " " .. " Config", ":e $MYVIMRC <CR>"),
        dashboard.button("s", " " .. " Restore Session", [[:lua require("persistence").load() <cr>]]),
        dashboard.button("l", "󰒲 " .. " Lazy", ":Lazy<CR>"),
        dashboard.button("q", " " .. " Quit", ":qa<CR>"),
      }
      for _, button in ipairs(dashboard.section.buttons.val) do
        button.opts.hl = "AlphaButtons"
        button.opts.hl_shortcut = "AlphaShortcut"
      end
      dashboard.section.header.opts.hl = "AlphaHeader"
      dashboard.section.buttons.opts.hl = "AlphaButtons"
      dashboard.section.footer.opts.hl = "AlphaFooter"
      dashboard.opts.layout[1].val = 8
      return dashboard
    end,
    config = function(_, dashboard)
      -- close Lazy and re-open when the dashboard is ready
      if vim.o.filetype == "lazy" then
        vim.cmd.close()
        vim.api.nvim_create_autocmd("User", {
          pattern = "AlphaReady",
          callback = function()
            require("lazy").show()
          end,
        })
      end

      require("alpha").setup(dashboard.opts)

      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimStarted",
        callback = function()
          local stats = require("lazy").stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          dashboard.section.footer.val = "⚡ Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms"
          pcall(vim.cmd.AlphaRedraw)
        end,
      })
    end,
  },
}, {
  performance = {
    rtp = {
      reset = false,
    },
  },
})

-- ----------------------------------------------------------------------------------------------
-- #Options
-- These are mostly taken from:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

vim.opt.autowrite = true -- Enable auto write
vim.opt.completeopt = "menu,menuone,noselect"
-- vim.opt.conceallevel = 3 -- Hide * markup for bold and italic
vim.opt.conceallevel = 0
vim.opt.confirm = true -- Confirm to save changes before exiting modified buffer
vim.opt.cursorline = true -- Enable highlighting of the current line
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.formatoptions = "jcqlnt" -- tcqj
vim.opt.textwidth = 100
vim.opt.grepformat = "%f:%l:%c:%m"
vim.opt.grepprg = "rg --vimgrep"
vim.opt.ignorecase = true -- Ignore case
vim.opt.inccommand = "nosplit" -- preview incremental substitute
vim.opt.laststatus = 0
-- vim.opt.list = true -- Show some invisible characters (tabs...
-- Disable the mouse.
vim.opt.mouse = nil
vim.opt.number = true -- Print line number
vim.opt.pumblend = 10 -- Popup blend
vim.opt.pumheight = 10 -- Maximum number of entries in a popup
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.scrolloff = 10 -- Lines of context
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize" }
vim.opt.shiftround = true -- Round indent
vim.opt.shiftwidth = 4 -- Size of an indent
vim.opt.shortmess:append { W = true, I = true, c = true }
vim.opt.showmode = false -- Dont show mode since we have a statusline
vim.opt.sidescrolloff = 8 -- Columns of context
-- This is the column that displays line status. I prever to keep it off.
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true -- Don't ignore case with capitals
vim.opt.smartindent = true -- Insert indents automatically
vim.opt.spelllang = {"en"}
vim.opt.splitbelow = true -- Put new windows below current
vim.opt.splitright = true -- Put new windows right of current
vim.opt.tabstop = 4 -- Number of spaces tabs count for
vim.opt.termguicolors = true -- True color support
vim.opt.timeoutlen = 300
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.updatetime = 200 -- Save swap file and trigger CursorHold
vim.opt.wildmode = "longest:full,full" -- Command-line completion mode
vim.opt.winminwidth = 5 -- Minimum window width
vim.opt.timeoutlen = 10000 -- Wait 10000 for next key press.

if vim.fn.has("nvim-0.9.0") == 1 then
  vim.opt.splitkeep = "screen"
  vim.opt.shortmess:append { C = true }
end

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0

-- ----------------------------------------------------------------------------------------------
-- #Keymaps
-- These are mostly taken from:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

vim.keymap.set({"n", "v"}, "<CR>", "10j", {desc = "Move cursor down 10 lines"})
vim.keymap.set({"n", "v"}, "<S-CR>", "10k", {desc = "Move cursor up 10 lines"})

vim.keymap.set("n", "<Space>", "<NOP>", {desc = "Unmap leader key"})

-- local Util = require("lazyvim.util")

-- better up/down
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", {expr = true, silent = true})
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", {expr = true, silent = true})

-- Move to window using the CTRL + SHIFT + hjkl keys
vim.keymap.set("n", "<C-h>", "<C-w>h", {desc = "Go to left window"})
vim.keymap.set("n", "<C-j>", "<C-w>j", {desc = "Go to lower window"})
vim.keymap.set("n", "<C-k>", "<C-w>k", {desc = "Go to upper window"})
vim.keymap.set("n", "<C-l>", "<C-w>l", {desc = "Go to right window"})

-- Resize window using <ctrl> arrow keys
-- vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
-- vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
-- vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
-- vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Move Lines
vim.keymap.set("n", "<A-j>", "<cmd>m .+1<cr>==", {desc = "Move down"})
vim.keymap.set("n", "<A-k>", "<cmd>m .-2<cr>==", {desc = "Move up"})
-- vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", {desc = "Move down"})
-- vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", {desc = "Move up"})
vim.keymap.set("v", "<A-j>", ":m '>+1<cr>gv=gv", {desc = "Move down"})
vim.keymap.set("v", "<A-k>", ":m '<-2<cr>gv=gv", {desc = "Move up"})

-- buffers
-- if Util.has("bufferline.nvim") then
--   vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
--   vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
--   vim.keymap.set("n", "[b", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
--   vim.keymap.set("n", "]b", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
-- else
--   vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
--   vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
--   vim.keymap.set("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
--   vim.keymap.set("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
-- end
-- vim.keymap.set("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
-- vim.keymap.set("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })

-- Clear search with <Esc>
vim.keymap.set({"n"}, "<Esc>", "<CMD>nohlsearch<CR><Esc>", {desc = "Clear hlsearch"})

-- Clear search, diff update and redraw
-- taken from runtime/lua/_editor.lua
vim.keymap.set(
  {"n"},
  "<leader>ll",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  {desc = "Redraw / clear hlsearch / diff update"}
)

vim.keymap.set({"n", "x"}, "gw", "*N", {desc = "Search word under cursor"})

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
vim.keymap.set("n", "n", "'Nn'[v:searchforward]", {expr = true, desc = "Next search result"})
vim.keymap.set("x", "n", "'Nn'[v:searchforward]", {expr = true, desc = "Next search result"})
vim.keymap.set("o", "n", "'Nn'[v:searchforward]", {expr = true, desc = "Next search result"})
vim.keymap.set("n", "N", "'nN'[v:searchforward]", {expr = true, desc = "Prev search result"})
vim.keymap.set("x", "N", "'nN'[v:searchforward]", {expr = true, desc = "Prev search result"})
vim.keymap.set("o", "N", "'nN'[v:searchforward]", {expr = true, desc = "Prev search result"})

-- Add undo break-points
-- vim.keymap.set("i", ",", ",<c-g>u")
-- vim.keymap.set("i", ".", ".<c-g>u")
-- vim.keymap.set("i", ";", ";<c-g>u")

-- save file
-- vim.keymap.set({ "i", "v", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- better indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- lazy
-- vim.keymap.set("n", "<leader>l", "<cmd>:Lazy<cr>", { desc = "Lazy" })

-- new file
-- vim.keymap.set("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- vim.keymap.set("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
-- vim.keymap.set("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })

-- if not Util.has("trouble.nvim") then
--   vim.keymap.set("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix" })
--   vim.keymap.set("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" })
-- end

-- stylua: ignore start

-- toggle options
-- vim.keymap.set("n", "<leader>uf", require("lazyvim.plugins.lsp.format").toggle, { desc = "Toggle format on Save" })
-- vim.keymap.set("n", "<leader>us", function() Util.toggle("spell") end, { desc = "Toggle Spelling" })
-- vim.keymap.set("n", "<leader>uw", function() Util.toggle("wrap") end, { desc = "Toggle Word Wrap" })
-- vim.keymap.set("n", "<leader>ul", function() Util.toggle("relativenumber", true) Util.toggle("number") end, { desc = "Toggle Line Numbers" })
-- vim.keymap.set("n", "<leader>ud", Util.toggle_diagnostics, { desc = "Toggle Diagnostics" })
-- local conceallevel = vim.o.conceallevel > 0 and vim.o.conceallevel or 3
-- vim.keymap.set("n", "<leader>uc", function() Util.toggle("conceallevel", false, {0, conceallevel}) end, { desc = "Toggle Conceal" })

-- lazygit
-- vim.keymap.set("n", "<leader>gg", function() Util.float_term({ "lazygit" }, { cwd = Util.get_root() }) end, { desc = "Lazygit (root dir)" })
-- vim.keymap.set("n", "<leader>gG", function() Util.float_term({ "lazygit" }) end, { desc = "Lazygit (cwd)" })

-- quit
-- vim.keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- highlights under cursor
if vim.fn.has("nvim-0.9.0") == 1 then
  vim.keymap.set("n", "<leader>vi", vim.show_pos, {desc = "Inspect Pos"})
end

-- Close all buffers except for current one.
vim.keymap.set("n", "<leader>bd", "<cmd>%bd | e# | bd#<cr>", {desc = "Close all buffers except current"})

-- Nicer behavior for CTRL + o, CTRL + i.
vim.keymap.set("n", "<C-o>", "<C-o>zz")
vim.keymap.set("n", "<C-i>", "<C-i>zz")

-- floating terminal
-- vim.keymap.set("n", "<leader>ft", function() Util.float_term(nil, { cwd = Util.get_root() }) end, { desc = "Terminal (root dir)" })
-- vim.keymap.set("n", "<leader>fT", function() Util.float_term() end, { desc = "Terminal (cwd)" })
-- vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>", {desc = "Enter Normal Mode"})

-- -- windows
-- vim.keymap.set("n", "<leader>ww", "<C-W>p", { desc = "Other window" })
-- vim.keymap.set("n", "<leader>wd", "<C-W>c", { desc = "Delete window" })
-- vim.keymap.set("n", "<leader>w-", "<C-W>s", { desc = "Split window below" })
-- vim.keymap.set("n", "<leader>w|", "<C-W>v", { desc = "Split window right" })
-- vim.keymap.set("n", "<leader>-", "<C-W>s", { desc = "Split window below" })
-- vim.keymap.set("n", "<leader>|", "<C-W>v", { desc = "Split window right" })

-- -- tabs
-- vim.keymap.set("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
-- vim.keymap.set("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
-- vim.keymap.set("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
-- vim.keymap.set("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
-- vim.keymap.set("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
-- vim.keymap.set("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- ----------------------------------------------------------------------------------------------
-- #Autocommands
-- These are mostly taken from:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Don't allow Lua nvim config to override formatoptions.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  command = "setlocal formatoptions-=ro",
})

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = vim.api.nvim_create_augroup("checktime", {clear = true}),
  command = "checktime",
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", {clear = true}),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = vim.api.nvim_create_augroup("resize_splits", {clear = true}),
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- -- go to last loc when opening a buffer
-- vim.api.nvim_create_autocmd("BufReadPost", {
--   group = vim.api.nvim_create_augroup("last_loc", {clear = true}),
--   callback = function()
--     local mark = vim.api.nvim_buf_get_mark(0, '"')
--     local lcount = vim.api.nvim_buf_line_count(0)
--     if mark[1] > 0 and mark[1] <= lcount then
--       pcall(vim.api.nvim_win_set_cursor, 0, mark)
--     end
--   end,
-- })

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("close_with_q", {clear = true}),
  pattern = {
    "PlenaryTestPopup",
    "help",
    "lspinfo",
    "man",
    "notify",
    "qf",
    "spectre_panel",
    "startuptime",
    "tsplayground",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Settings for gitcommit, markdown files.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("gitcommit_settings", {clear = true}),
  pattern = {"gitcommit", "markdown"},
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.textwidth = 9999
    vim.opt_local.spell = true
  end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd({"BufWritePre"}, {
  group = vim.api.nvim_create_augroup("auto_create_dir", {clear = true}),
  callback = function(event)
    local file = vim.loop.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

