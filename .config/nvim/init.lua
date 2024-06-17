local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

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
  operations = {
    buffer = "󰭷 ",
    code = " ",
    find = "󰈞 ",
    debug = " ",
    git = "󰊢 ",
  },
}

local filepath = vim.fn.expand("%")
if filepath == "" or filepath == nil then
  filepath = vim.fn.getcwd()
end

local plugins = {}

-- ----------------------------------------------------------------------------------------------
-- #Utility plugins
table.insert(plugins, {
  -- Run :StartupTime to see which plugins are slow.
  "dstein64/vim-startuptime",
  cmd = "StartupTime",
  config = function()
    vim.g.startuptime_tries = 10
  end,
})
table.insert(plugins, {
  -- Required for Telescope and others.
  "nvim-lua/plenary.nvim",
  lazy = true,
})
table.insert(plugins, {
  -- Disable certain features for large files (default = 2MB).
  "LunarVim/bigfile.nvim",
})

-- ----------------------------------------------------------------------------------------------
-- #Editor plugins
table.insert(plugins, {
  "nmac427/guess-indent.nvim",
  config = function()
    require("guess-indent").setup({})
  end,
})
table.insert(plugins, {
  "numToStr/Comment.nvim",
  dependencies = {
    {
      "JoosepAlviste/nvim-ts-context-commentstring",
      lazy = true,
      config = function()
        require("ts_context_commentstring").setup({})
        vim.g.skip_ts_context_commentstring_module = true
      end
    },
  },
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
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
    })
  end,
})
table.insert(plugins, {
  "hrsh7th/nvim-cmp",
  version = false, -- Doesn't use releases
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "saadparwaiz1/cmp_luasnip",
    "lukas-reineke/cmp-under-comparator",
    {
      "zbirenbaum/copilot-cmp",
      config = function()
        require("copilot_cmp").setup()
      end,
    },
  },
  config = function()
    local has_words_before = function()
      unpack = unpack or table.unpack
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
    end
    local luasnip = require("luasnip")
    local cmp = require("cmp")
    cmp.setup({
      -- Disable first option being automatically selected.
      preselect = cmp.PreselectMode.None,
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      completion = {
        completeopt = "menu,menuone,noselect"
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
        end, {"i", "s"}),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, {"i", "s"}),
        ["<CR>"] = cmp.mapping({
          i = function(fallback)
            if cmp.visible() and cmp.get_active_entry() then
              cmp.confirm({behavior = cmp.ConfirmBehavior.Replace, select = false})
            else
              fallback()
            end
          end,
          s = cmp.mapping.confirm({select = true}),
          c = cmp.mapping.confirm({behavior = cmp.ConfirmBehavior.Replace, select = true})
        }),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      },
      sources = cmp.config.sources({
        {name = "copilot"},
        {name = "nvim_lsp"},
        {name = "luasnip"},
        {name = "buffer"},
        {name = "path"},
      }),
      formatting = {
        format = function(_, item)
          if icons.kinds[item.kind] then
            item.kind = icons.kinds[item.kind] .. item.kind
          end
          return item
        end,
      },
      sorting = {
        comparators = {
          cmp.config.compare.offset,
          cmp.config.compare.exact,
          cmp.config.compare.score,
          cmp.config.compare.recently_used,
          require("cmp-under-comparator").under,
          cmp.config.compare.kind,
        },
      },
    })
  end,
})
table.insert(plugins, {
  "L3MON4D3/LuaSnip",
  dependencies = {
    "rafamadriz/friendly-snippets",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
  -- keys = function()
  --   -- Disable keymap so we can set up supertab in nvim-cmp
  --   ---@type string[]
  --   return {}
  -- end,
  config = function()
    require("luasnip").setup({
      history = true,
      region_check_events = "CursorMoved",
      delete_check_events = "TextChanged",
    })
  end,
})
table.insert(plugins, {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  config = function()
    require("copilot").setup({
      panel = {
        enabled = false,
      },
      suggestion = {
        enabled = false,
      },
    })
  end,
})
table.insert(plugins, {
  "folke/flash.nvim",
  event = "VeryLazy",
  config = function()
    require("flash").setup({
      modes = {
        search = {
          enabled = false,
        },
        char = {
          enabled = false,
        },
      },
    })
    vim.keymap.set({"n", "x", "o"}, "s", "<cmd>lua require('flash').jump()<cr>", {desc = "Flash"})
  end,
})
table.insert(plugins, {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 1000
    local whichkey = require("which-key")
    whichkey.setup({
      icons = {
        group = "", -- we'll use custom icons
      },
      triggers_nowait = {
        -- registers
        '"',
        "<c-r>",
        -- spelling
        "z=",
      },
      disable = {
        filetypes = {"TelescopePrompt"},
      }
    })
    whichkey.register({
      ["<leader>b"] = {name = icons.operations.buffer .. "Buffer"},
      ["<leader>c"] = {name = icons.operations.code .. "Code"},
      ["<leader>d"] = {name = icons.operations.code .. "Debug"},
      ["<leader>f"] = {name = icons.operations.find .. "Find"},
      ["<leader>g"] = {name = icons.operations.git .. "Git"},
    })
  end,
})

-- ----------------------------------------------------------------------------------------------
-- #Treesitter plugins
table.insert(plugins, {
  "nvim-treesitter/nvim-treesitter",
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
      },
    })
  end,
})
table.insert(plugins, {
  "nvim-treesitter/nvim-treesitter-context",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("treesitter-context").setup({
      multiline_threshold = 1,
    })
  end,
})
table.insert(plugins, {
  "Wansmer/treesj",
  dependencies = {"nvim-treesitter/nvim-treesitter"},
  config = function()
    require("treesj").setup({
      use_default_keymaps = false,
    })
    vim.keymap.set("n", "<leader>j", "<cmd>lua require('treesj').toggle()<cr>", {desc = "Split join"})
  end,
})

-- ----------------------------------------------------------------------------------------------
-- #LSP plugins
table.insert(plugins, {
  "neovim/nvim-lspconfig",
  event = {"BufReadPre", "BufNewFile"},
  dependencies = {
    {
      "folke/neodev.nvim",
      config = function()
        require("neodev").setup()
      end,
    },
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    local lspconfig = require("lspconfig")
    -- local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
    local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      require("cmp_nvim_lsp").default_capabilities()
    )
    lspconfig.jsonls.setup({
      capabilities = vim.deepcopy(capabilities),
    })
    lspconfig.lua_ls.setup({
      capabilities = vim.deepcopy(capabilities),
      on_init = function(client)
        local path = vim.fn.getcwd()
        if vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc") then
          return
        end

        client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
          runtime = {
            version = "LuaJIT"
          },
          -- Make the server aware of Neovim runtime files.
          workspace = {
            checkThirdParty = false,
            library = {
              vim.env.VIMRUNTIME,
            },
          },
        })
      end,
      settings = {
        Lua = {
          completion = {
            callSnippet = "Replace",
          },
        },
      },
    })
    lspconfig.tsserver.setup({
      capabilities = vim.deepcopy(capabilities),
      settings = {
        diagnostics = {
          -- https://github.com/microsoft/TypeScript/blob/main/src/compiler/diagnosticMessages.json
          ignoredCodes = {
            80006,
          },
        },
      },
    })
    lspconfig.eslint.setup({
      capabilities = vim.deepcopy(capabilities),
      filetypes = {"javascript", "javascriptreact", "typescript", "typescriptreact"},
    })
    local python_extra_paths = {}
    if string.find(filepath, "outset%-ai/webrtc") then
      table.insert(python_extra_paths, "~/OrbStack/docker/volumes/webrtc_python312_packages")
    elseif string.find(filepath, "outset%-ai/backend") then
      table.insert(python_extra_paths, "~/OrbStack/docker/volumes/backend_python_packages_312")
    end
    lspconfig.pyright.setup({
      capabilities = vim.deepcopy(capabilities),
      settings = {
        python = {
          analysis = {
            typeCheckingMode = "basic",
            pythonPath = "/opt/homebrew/bin/python3",
            extraPaths = python_extra_paths,
            -- extraPaths = {
            --   "~/OrbStack/docker/volumes/backend_python_packages_312",
            -- },
          },
        },
      },
    })
    lspconfig.rust_analyzer.setup({
      capabilities = vim.deepcopy(capabilities),
    })
    lspconfig.tailwindcss.setup({
      capabilities = vim.deepcopy(capabilities),
    })

    local function diagnostic_goto(next, severity)
      local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
      severity = severity and vim.diagnostic.severity[severity] or nil
      return function()
        go({severity = severity})
      end
    end
    vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, {desc = "Line diagnostics"})
    vim.keymap.set("n", "<leader>cl", "<cmd>LspInfo<cr>", {desc = "Lsp info"})
    vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<cr>", {desc = "Goto definition"})
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {desc = "Goto declaration"})
    vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<cr>", {desc = "Goto type definition"})
    vim.keymap.set("n", "gI", "<cmd>Telescope lsp_implementations<cr>", {desc = "Goto implementation"})
    vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references show_line=false<cr>", {desc = "References"})
    vim.keymap.set("n", "K", vim.lsp.buf.hover, {desc = "Hover"})
    vim.keymap.set("n", "gj", diagnostic_goto(true), {desc = "Next diagnostic"})
    vim.keymap.set("n", "gk", diagnostic_goto(false), {desc = "Prev diagnostic"})
    vim.keymap.set("n", "ge", diagnostic_goto(true, "ERROR"), {desc = "Next error"})
    vim.keymap.set("n", "gE", diagnostic_goto(false, "ERROR"), {desc = "Prev error"})
    vim.keymap.set("n", "gq", diagnostic_goto(true, "WARN"), {desc = "Next warning"})
    vim.keymap.set("n", "gQ", diagnostic_goto(false, "WARN"), {desc = "Prev warning"})
    vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, {desc = "Rename token"})
    vim.keymap.set(
      "n",
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
      {desc = "Source code action"}
    )

    vim.diagnostic.config({
      underline = true,
      update_in_insert = false,
      virtual_text = {spacing = 4, source="if_many", prefix = "●"},
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
          [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
          [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
          [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
        },
      },
    })
  end,
})
table.insert(plugins, {
  "williamboman/mason.nvim",
  cmd = "Mason",
  config = function()
    require("mason").setup({
      ensure_installed = {
        "stylua",
        "shfmt",
      },
    })
  end,
})
table.insert(plugins, {
  "luckasRanarison/clear-action.nvim",
  config = function()
    require("clear-action").setup({
      signs = {
        position = "right_align",
      },
      mappings = {
        code_action = {"<leader>ca", "Code action"},
      },
    })
  end,
})
table.insert(plugins, {
  "j-hui/fidget.nvim",
  config = function()
    require("fidget").setup()
  end,
})

-- ----------------------------------------------------------------------------------------------
-- #Debugging plugins
table.insert(plugins, {
  "mfussenegger/nvim-dap-python",
  dependencies = {
    "mfussenegger/nvim-dap",
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
  },
  config = function()
    local dap = require("dap")
    local dap_python = require("dap-python")
    local dap_ui = require("dapui")
    dap_python.setup("/opt/homebrew/bin/python3")
    dap.configurations.python = {
      {
        justMyCode = false,
        type = "python",
        request = "attach",
        name = "Attach to Docker",
        host = "127.0.0.1",
        port = 5678,
        pythonPath = function()
          return "/opt/homebrew/bin/python3"
        end,
        pathMappings = {
          {
            localRoot = vim.fn.getcwd(),
            remoteRoot = "/code",
          },
        }
      },
    }
    dap_ui.setup({
      layouts = {
        {
          elements = {
            {id = "scopes", size = 0.5},
            {id = "breakpoints", size = 0.5},
          },
          position = "left",
          size = 40,
        },
        {
          elements = {
            {id = "repl", size = 1.0},
          },
          position = "bottom",
          size = 20,
        },
      },
    })
    -- Open and close debugging UI when debugger is attached/unattached. 
    dap.listeners.before.attach.dapui_config = dap_ui.open
    dap.listeners.before.launch.dapui_config = dap_ui.open
    dap.listeners.before.event_terminated.dapui_config = dap_ui.close
    dap.listeners.before.event_exited.dapui_config = dap_ui.close

    vim.keymap.set("n", "<leader>db", "<cmd>lua require('dap').toggle_breakpoint()<cr>", {desc = "Toggle breakpoint"})
    vim.keymap.set("n", "<leader>dl", "<cmd>lua require('dap').clear_breakpoints()<cr>", {desc = "Clear all breakpoints"})
    vim.keymap.set("n", "<leader>dc", "<cmd>lua require('dap').continue()<cr>", {desc = "Continue debugging"})
    vim.keymap.set("n", "<leader>dn", "<cmd>lua require('dap').step_over()<cr>", {desc = "Debugging step to next line"})
    vim.keymap.set("n", "<leader>dN", "<cmd>lua require('dap').step_into()<cr>", {desc = "Debugging step into function"})
    vim.keymap.set("n", "<leader>de", "<cmd>lua require('dap').set_exception_breakpoints({'raised', 'uncaught'})<cr>", {desc = "Create debugging breakpoint on exception"})
    vim.keymap.set("n", "<leader>du", "<cmd>lua require('dapui').toggle()<cr>", {desc = "Toggle debugging UI"})
    vim.keymap.set("n", "<leader>dk", "<cmd>lua require('dapui').eval()<cr>", {desc = "Debugging hover"})
  end,
})

-- ----------------------------------------------------------------------------------------------
-- #Git plugins
table.insert(plugins, {
  "akinsho/git-conflict.nvim",
  version = "1.1.1",
  config = function()
    require("git-conflict").setup({
      default_mappings = false,
    })
    vim.keymap.set("n", "<leader>gco", "<cmd>GitConflictChooseOurs<cr>", {desc = "Git conflict choose ours"})
    vim.keymap.set("n", "<leader>gct", "<cmd>GitConflictChooseTheirs<cr>", {desc = "Git conflict choose theirs"})
    vim.keymap.set("n", "<leader>gcb", "<cmd>GitConflictChooseBoth<cr>", {desc = "Git conflict choose both"})
    vim.keymap.set("n", "<leader>gc0", "<cmd>GitConflictChooseNone<cr>", {desc = "Git conflict choose none"})
    vim.keymap.set("n", "go", "<cmd>GitConflictNextConflict<cr>", {desc = "Git conflict jump next"})
    vim.keymap.set("n", "gp", "<cmd>GitConflictPrevConflict<cr>", {desc = "Git conflict jump prev"})
  end,
})
table.insert(plugins, {
  "lewis6991/gitsigns.nvim",
  config = function()
    local gitsigns = require("gitsigns")
    gitsigns.setup()
    vim.keymap.set("n", "<leader>gb", gitsigns.blame_line, {desc = "Git blame line"})
    vim.keymap.set("n", "<leader>gB", function() gitsigns.blame_line({full = true}) end, {desc = "Git blame line (full)"})
    vim.keymap.set("n", "<leader>gd", gitsigns.diffthis, {desc = "Git diff line"})
  end,
})

-- ----------------------------------------------------------------------------------------------
-- #Colorscheme plugins
table.insert(plugins, {
  "diegoulloao/neofusion.nvim",
  -- config = function()
  --   vim.opt.background = "dark"
  --   vim.cmd("colorscheme neofusion")
  --   require("lualine").options.theme = require("neofusion.lualine")
  -- end,
})
table.insert(plugins, {
  "mellow-theme/mellow.nvim",
  -- config = function()
  --   vim.cmd("colorscheme mellow")
  -- end
})
table.insert(plugins, {
  "rebelot/kanagawa.nvim",
  config = function()
    vim.cmd("colorscheme kanagawa")
  end,
})

-- ----------------------------------------------------------------------------------------------
-- #UI plugins
table.insert(plugins, {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  config = function()
    local function fg(name)
      return function()
        ---@type {foreground?:number}?
        local hl = vim.api.nvim_get_hl_by_name(name, true)
        return hl and hl.foreground and { fg = string.format("#%06x", hl.foreground) }
      end
    end
    local lualine = require("lualine")
    lualine.setup({
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
          {"filename", path = 1, symbols = {modified = "  ", readonly = "", unnamed = ""}},
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
    })
  end,
})
table.insert(plugins, {
  "stevearc/dressing.nvim",
  config = function()
    require("dressing").setup({
      input = {
        -- Allow entering Normal mode.
        insert_only = false,
      },
    })
  end,
})
table.insert(plugins, {
  "nvim-tree/nvim-web-devicons",
  lazy = true,
})
table.insert(plugins, {
  "lukas-reineke/indent-blankline.nvim",
  event = {"BufReadPost", "BufNewFile"},
  config = function()
    require("ibl").setup({
      indent = {
        char = "▏",
      },
      whitespace = {
        remove_blankline_trail = true,
      },
      scope = {
        enabled = false,
      },
    })
  end,
})
table.insert(plugins, {
  "nvim-telescope/telescope-fzf-native.nvim",
  build = "make"
})
table.insert(plugins, {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("telescope").setup({
      extensions = {
        fzf = {
          fuzzy = false,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
      defaults = {
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
        path_display = {"truncate"},
      },
    })
    require("telescope").load_extension("fzf")
  end,
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
        opts = vim.tbl_deep_extend("force", {cwd = get_root()}, opts or {})
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
        telescope_fn("files", {cwd = false, path_display = {"truncate"}}),
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
        "<leader>fG",
        telescope_fn("grep_string"),
        desc = "Find hovered string in files (grep)",
      },
      {
        "<leader>fs",
        "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
        desc = "Buffers",
      },
      {
        "<leader>fa",
        "<cmd>Telescope pickers<cr>",
        desc = "Pickers",
      },
      {
        "<leader>fr",
        "<cmd>Telescope oldfiles<cr>",
        desc = "Recent files",
      },
      {
        "<leader>fC",
        "<cmd>Telescope colorscheme enable_preview=true<cr>",
        desc = "Color scheme picker",
      },
      {
        "<leader>fK",
        "<cmd>Telescope keymaps<cr>",
        desc = "Keymaps",
      },
    }
  end,
})
table.insert(plugins, {
  "stevearc/oil.nvim",
  dependencies = {"nvim-tree/nvim-web-devicons"},
  config = function()
    local oil = require("oil")
    oil.setup({
      keymaps = {
        ["q"] = "actions.close",
      },
      view_options = {
        show_hidden_files = true,
      },
    })
    local function open_oil()
      oil.open()
      -- local oil_util = require("oil.util")
      -- require("oil.util").run_after_load(0, function()
      --   if not oil_util.get_preview_win() then
      --     oil.open_preview()
      --   end
      -- end)
    end
    vim.keymap.set("n", "<leader>fd", open_oil, {desc = "Open oil file explorer"})
  end,
})
table.insert(plugins, {
  "goolord/alpha-nvim",
  event = "VimEnter",
  opts = function()
    local dashboard = require("alpha.themes.dashboard")
    local logo = [[
    ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
    ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
    ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
    ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
    ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
    ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
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
})

require("lazy").setup(plugins)

-- ------------------------------------------------------------------------------------------------
-- #Options
vim.opt.autowrite = true -- Enable auto write
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.conceallevel = 0 -- Show text as is
vim.opt.confirm = true -- Confirm to save changes before exiting modified buffer
vim.opt.cursorline = true -- Enable highlighting of the current line
-- j: Remove comment leader when joining lines.
-- c: Auto-wrap comments using textwidth.
-- l: Long lines are not broken in insert mode.
-- n: When formatting text, recognized numbered lists.
vim.opt.formatoptions = "jcln"
vim.opt.textwidth = 100
vim.opt.grepformat = "%f:%l:%c:%m"
vim.opt.grepprg = "rg --vimgrep"
vim.opt.laststatus = 0
-- Gutter columns
vim.opt.number = true -- Line number in gutter
vim.opt.relativenumber = true -- Relative line number in gutter
vim.opt.signcolumn = "yes" -- Line status in gutter
-- Scrolling
vim.opt.scrolloff = 10 -- Lines of context
vim.opt.sidescrolloff = 8 -- Columns of context
-- Indenting
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.shiftwidth = 4 -- Size of an indent
vim.opt.shiftround = true -- Round indent to nearest shiftwidth
vim.opt.tabstop = 4 -- Number of spaces tabs count for
vim.opt.smartindent = true -- Insert indents automatically
-- Window splitting
vim.opt.splitbelow = true -- Put new windows below current
vim.opt.splitright = true -- Put new windows right of current
vim.opt.winminwidth = 5 -- Minimum window width for splits
vim.opt.splitkeep = "screen"

vim.opt.ignorecase = true -- Don't ignore case with capitals when searching
vim.opt.smartcase = true -- Don't ignore case with capitals when searching
vim.opt.timeoutlen = 10000 -- Wait 10000 for next key press.
vim.opt.updatetime = 200 -- Save swap file and trigger CursorHold
vim.opt.spelllang = {"en"}
vim.opt.termguicolors = true -- True color support
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.mouse = "" -- Disable the mouse
vim.opt.shortmess:append({W = true, I = true, c = true, C = true})
vim.opt.showmode = false -- Dont show mode since we have a statusline
vim.opt.pumblend = 10 -- Popup blend
vim.opt.pumheight = 10 -- Maximum number of entries in a popup
vim.opt.list = true
vim.opt.listchars = {tab = "» ", trail = "·", nbsp = "␣"}

-- ------------------------------------------------------------------------------------------------
-- #Keymaps
vim.keymap.set("n", "<Space>", "<NOP>", {desc = "Unmap leader key"})
vim.keymap.set({"n", "v"}, "<CR>", "10j", {desc = "Jump down 10 lines"})
vim.keymap.set({"n", "v"}, "<S-CR>", "10k", {desc = "Jump up 10 lines"})
-- Better up/down.
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", {expr = true, silent = true})
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", {expr = true, silent = true})
-- Move to window using the CTRL + SHIFT + hjkl keys
vim.keymap.set("n", "<C-h>", "<C-w>h", {desc = "Go to left window"})
vim.keymap.set("n", "<C-j>", "<C-w>j", {desc = "Go to lower window"})
vim.keymap.set("n", "<C-k>", "<C-w>k", {desc = "Go to upper window"})
vim.keymap.set("n", "<C-l>", "<C-w>l", {desc = "Go to right window"})

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
vim.keymap.set({"n", "x", "o"}, "n", "'Nn'[v:searchforward]", {expr = true, desc = "Next search result"})
vim.keymap.set({"n", "x", "o"}, "N", "'nN'[v:searchforward]", {expr = true, desc = "Prev search result"})

-- Better indenting.
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Inspect word under cursor.
vim.keymap.set("n", "<leader>ki", vim.show_pos, {desc = "Inspect position"})

-- Close all buffers except for current one.
vim.keymap.set("n", "<leader>bd", "<cmd>%bd | e# | bd#<cr>", {desc = "Close all buffers except current"})

-- Nicer behavior for CTRL + o, CTRL + i.
vim.keymap.set("n", "<C-o>", "<C-o>zz")
vim.keymap.set("n", "<C-i>", "<C-i>zz")

vim.keymap.set({"n", "v"}, "<leader>y", '"+y', {desc = "Copy to system clipboard"})

vim.keymap.set({"n", "x"}, "c", '"_c', {desc = "Change without yanking"})
vim.keymap.set(
  {"n"},
  "x",
  function()
    if vim.fn.col(".") == 1 then
      local line = vim.fn.getline(".")
      if line:match("^%s*$") then
        vim.api.nvim_feedkeys('"_dd', "n", false)
        vim.api.nvim_feedkeys("$", "n", false)
      else
        vim.api.nvim_feedkeys('"_x', "n", false)
      end
    else
      vim.api.nvim_feedkeys('"_x', "n", false)
    end
  end,
  {desc = "Delete character without yanking"}
)

-- ------------------------------------------------------------------------------------------------
-- #Autocommands
-- Check if we need to reload the file when it changed.
vim.api.nvim_create_autocmd({"FocusGained", "TermClose", "TermLeave"}, {
  group = vim.api.nvim_create_augroup("checktime", {clear = true}),
  command = "checktime",
})

-- Highlight on yank.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", {clear = true}),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Resize splits when window is resized.
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = vim.api.nvim_create_augroup("resize_splits", {clear = true}),
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- Close some filetypes with "q".
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
    vim.keymap.set("n", "q", "<cmd>close<cr>", {buffer = event.buf, silent = true})
  end,
})

-- Turn off some options for gitcommit, markdown files.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("gitcommit_markdown_files", {clear = true}),
  pattern = {"gitcommit", "markdown"},
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.textwidth = 9999
    vim.opt_local.spell = true
  end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("auto_create_dir", {clear = true}),
  callback = function(event)
    local file = vim.loop.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- No really, I don't want comment tokens on newlines.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("format_options", {clear = true}),
  pattern = {"*"},
  callback = function()
    vim.opt_local.fo:remove("o")
    vim.opt_local.fo:remove("r")
  end,
})
