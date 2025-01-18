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
    peek = "󰈈 ",
    flash = " ",
    toolbox = "󰦬 ",
  },
}

local Project = {
  UNSET = 0,
  OUTSET_BACKEND = 1,
  OUTSET_FRONTEND = 2,
  OUTSET_WEBRTC = 3,
}
local filepath = vim.fn.expand("%:p")
if filepath == "" or filepath == nil then
  filepath = vim.fn.getcwd()
end
local project = Project.UNSET
if string.find(filepath, "outset%-ai/webrtc") then
  project = Project.OUTSET_WEBRTC
elseif string.find(filepath, "outset%-ai/backend") then
  project = Project.OUTSET_BACKEND
elseif string.find(filepath, "outset%-ai/frontend") then
  project = Project.OUTSET_FRONTEND
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
  enabled = true,
  version = false, -- Doesn't use releases
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "saadparwaiz1/cmp_luasnip",
    "lukas-reineke/cmp-under-comparator",
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
          elseif luasnip.expand_or_locally_jumpable() then
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
  config = function()
    require("luasnip").setup({
      region_check_events = "CursorMoved",
      delete_check_events = "TextChanged",
    })
  end,
})
table.insert(plugins, {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      panel = {
        enabled = false,
      },
      suggestion = {
        enabled = true,
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
    vim.keymap.set("n", "ss", "<cmd>lua require('flash').jump()<cr>", {desc = "Flash"})
  end,
})
-- table.insert(plugins, {
--   "gbprod/substitute.nvim",
--   config = function()
--     local substitute = require("substitute")
--     substitute.setup()
--     vim.keymap.set("n", "s", substitute.operator, {noremap = true})
--     vim.keymap.set("n", "S", substitute.line, {noremap = true})
--     vim.keymap.set({"v", "x"}, "s", substitute.visual, {noremap = true})
--   end,
-- })
table.insert(plugins, {
  "echasnovski/mini.surround",
  config = function()
    local surround = require("mini.surround")
    surround.setup()
  end,
})
table.insert(plugins, {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local whichkey = require("which-key")
    whichkey.setup({
      delay = 1000,
      icons = {
        -- Disable icons. We'll use our own.
        group = "",
        rules = false,
        colors = false,
      },
      spec = {
        {"<leader>b", group = icons.operations.buffer .. "Buffer"},
        {"<leader>c", group = icons.operations.code .. "Code"},
        {"<leader>d", group = icons.operations.debug .. "Debug"},
        {"<leader>f", group = icons.operations.find .. "Find"},
        {"<leader>g", group = icons.operations.git .. "Git"},
        {"<leader>k", group = icons.operations.peek .. "Peek"},
        {"<leader>t", group = icons.operations.toolbox .. "Toolbox"},
      },
      disable = {
        ft = {"TelescopePrompt"},
      }
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
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<leader>=",
          node_incremental = "<leader>=",
          scope_incremental = false,
          node_decremental = "<leader>-",
        },
      },
    })
  end,
})
table.insert(plugins, {
  "nvim-treesitter/nvim-treesitter-context",
  dependencies = {"nvim-treesitter/nvim-treesitter"},
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
table.insert(plugins, {
  "nvim-treesitter/nvim-treesitter-textobjects",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  event = "VeryLazy",
  config = function()
    require("nvim-treesitter.configs").setup({
      textobjects = {
        select = {
          enable = true,
          -- Automatically jump forward to textobject.
          lookahead = true,
          keymaps = {
            ["af"] = {query = "@function.outer", desc = "outer function/method"},
            ["if"] = {query = "@function.inner", desc = "inner function/method"},
            ["ai"] = {query = "@conditional.outer", desc = "outer conditional"},
            ["ii"] = {query = "@conditional.inner", desc = "inner conditional"},
            ["al"] = {query = "@loop.outer", desc = "outer loop"},
            ["il"] = {query = "@loop.inner", desc = "inner loop"},
            ["ac"] = {query = "@comment.outer", desc = "outer comment"},
            ["ic"] = {query = "@comment.inner", desc = "inner comment"},
            ["aC"] = {query = "@class.outer", desc = "outer class"},
            ["iC"] = {query = "@class.inner", desc = "inner class"},
          },
          selection_modes = function()
            return "V"
          end,
        },
        lsp_interop = {
          enable = true,
          peek_definition_code = {
            ["<leader>kf"] = "@function.outer",
            ["<leader>kc"] = "@class.outer",
          },
        },
      },
    })
  end
})

-- ----------------------------------------------------------------------------------------------
-- #LSP plugins
table.insert(plugins, {
  "neovim/nvim-lspconfig",
  event = {"BufReadPre", "BufNewFile"},
  dependencies = {
    "folke/lazydev.nvim",
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
    -- local capabilities = vim.lsp.protocol.make_client_capabilities()
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
    if next(vim.fs.find({"deno.json"}, {upward = true, limit = 1})) ~= nil then
      lspconfig.denols.setup({
        capabilities = vim.deepcopy(capabilities),
      })
    else
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
    end
    if next(vim.fs.find({".eslintrc", ".eslintrc.json", ".eslintrc.js", ".eslintrc.cjs"}, {upward = true, limit = 1})) ~= nil then
      lspconfig.eslint.setup({
        capabilities = vim.deepcopy(capabilities),
        filetypes = {"javascript", "javascriptreact", "typescript", "typescriptreact"},
      })
    end
    local python_extra_paths = {}
    if project == Project.OUTSET_WEBRTC then
      table.insert(python_extra_paths, "~/OrbStack/docker/volumes/webrtc_python311_packages")
    elseif project == Project.OUTSET_BACKEND then
      table.insert(python_extra_paths, "~/OrbStack/docker/volumes/backend_python_packages_312")
    end
    lspconfig.pyright.setup({
      capabilities = vim.deepcopy(capabilities),
      settings = {
        python = {
          analysis = {
            typeCheckingMode = "basic",
            -- pythonPath = "/opt/homebrew/bin/python3",
            extraPaths = python_extra_paths,
            -- stubPath = "/opt/homebrew/lib/python3.13/site-packages",
            stubPath = "~/.pyenv/versions/3.12.8/lib/python3.12/site-packages",
          },
        },
      },
    })
    lspconfig.tailwindcss.setup({
      capabilities = vim.deepcopy(capabilities),
    })
    lspconfig.clangd.setup({
      capabilities = vim.deepcopy(capabilities),
    })

    local function diagnostic_goto(next, severity)
      local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
      severity = severity and vim.diagnostic.severity[severity] or nil
      return function()
        go({severity = severity})
      end
    end
    local snacks = require("snacks")
    vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, {desc = "Line diagnostics"})
    vim.keymap.set("n", "<leader>cl", "<cmd>LspInfo<cr>", {desc = "Lsp info"})
    vim.keymap.set("n", "gd", function() snacks.picker.lsp_definitions() end, {desc = "Goto definition"})
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {desc = "Goto declaration"})
    vim.keymap.set("n", "gt", function() snacks.picker.lsp_type_definitions() end, {desc = "Goto type definition"})
    vim.keymap.set("n", "gr", function() snacks.picker.lsp_references() end, {desc = "References"})
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
  "Chaitanyabsprip/fastaction.nvim",
  config = function()
    local fastaction = require("fastaction")
    fastaction.setup({
      dismiss_keys = {"q", "<Esc>"},
    })
    vim.keymap.set({"n", "x"}, "<leader>ca", fastaction.code_action, {desc = "Code action"})
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
  "nvim-tree/nvim-web-devicons",
  lazy = true,
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
        show_hidden = true,
      },
    })
    vim.keymap.set("n", "<leader>fd", oil.open, {desc = "Open oil file explorer"})
    vim.api.nvim_create_autocmd("User", {
      pattern = "OilEnter",
      callback = vim.schedule_wrap(function(args)
        if vim.api.nvim_get_current_buf() == args.data.buf and oil.get_cursor_entry() then
          oil.open_preview()
        end
      end),
    })
  end,
})
table.insert(plugins, {
  "DanWlker/toolbox.nvim",
  config = function()
    require("toolbox").setup({
      commands = {
        {
          name = "Copy pytest path to clipboard",
          execute = function()
            local relative_path, _ = vim.fn.expand("%:p"):gsub(".*/backend", "backend", 1)
            local class_name = nil
            local function_name = nil
            local bufnr = vim.api.nvim_get_current_buf()
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))
            row = row - 1
            local parser = vim.treesitter.get_parser(bufnr, "python")
            local tree = parser:parse()[1]
            local root = tree:root()
            local node = root:descendant_for_range(row, col, row, col)
            while node do
              if node:type() == "class_definition" then
                local name_node = node:field("name")[1]
                if name_node then
                  class_name = vim.treesitter.get_node_text(name_node, bufnr)
                end
              elseif node:type() == "function_definition" then
                local name_node = node:field("name")[1]
                if name_node then
                  function_name = vim.treesitter.get_node_text(name_node, bufnr)
                end
              end
              node = node:parent()
            end
            local pytest_path = relative_path
            if class_name then
              pytest_path = pytest_path .. "::" .. class_name
            end
            if class_name and function_name then
              pytest_path = pytest_path .. "::" .. function_name
            end
            vim.fn.setreg("+", pytest_path)
            print("Copied \"" .. pytest_path .. "\" to clipboard")
          end,
        },
      },
    })
    vim.keymap.set({"n", "v"}, "<leader>t", require("toolbox").show_picker)
  end,
})

-- ----------------------------------------------------------------------------------------------
-- #Snacks
table.insert(plugins, {
  "folke/snacks.nvim",
  lazy = false,
  config = function()
    local snacks = require("snacks")
    snacks.setup({
      bigfile = {},
      picker = {
        formatters = {
          file = {
            filename_first = true,
          },
        },
      },
      dashboard = {},
      indent = {
        scope = {
          enabled = false,
        },
      },
      input = {},
      lazygit = {},
    })
    vim.keymap.set("n", "<leader>ff", function() snacks.picker.files({hidden = true}) end, {desc = "Find files"})
    vim.keymap.set("n", "<leader>fg", function() snacks.picker.grep() end, {desc = "Search text live"})
    vim.keymap.set({"n", "x"}, "<leader>fG", function() snacks.picker.grep_word() end, {desc = "Search word"})
    vim.keymap.set("n", "<leader>fs", function() snacks.picker.buffers() end, {desc = "Buffers"})
    vim.keymap.set("n", "<leader>fa", function() snacks.picker.pickers() end, {desc = "Open pickers"})
    vim.keymap.set("n", "<leader>fr", function() snacks.picker.recent() end, {desc = "Recent files"})
    vim.keymap.set("n", "<leader>fC", function() snacks.picker.colorschemes() end, {desc = "Color schemes"})
    vim.keymap.set("n", "<leader>fK", function() snacks.picker.keymaps() end, {desc = "Keymaps"})
    vim.keymap.set("n", "<leader>fw", function() snacks.picker.lsp_symbols() end, {desc = "Workspace symbols"})
    vim.keymap.set("n", "<leader>gs", function() snacks.picker.git_status() end, {desc = "Git status"})
    vim.keymap.set("n", "<leader>fp", function() snacks.picker.projects() end, {desc = "Projects"})
  end,
})

-- ------------------------------------------------------------------------------------------------
-- #Language specific
table.insert(plugins, {
  "mrcjkb/rustaceanvim",
  version = "^4",
  lazy = false,
})

-- ------------------------------------------------------------------------------------------------
-- #Setup lazy
require("lazy").setup({
  spec = plugins,
  dev = {
    path = "~/projects",
    fallback = false,
  },
})

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
vim.opt.shiftround = true -- Round indent to nearest shiftwidth
vim.opt.smartindent = true -- Insert indents automatically
if project == Project.OUTSET_FRONTEND then
  vim.opt.shiftwidth = 2 -- Size of an indent
  vim.opt.tabstop = 2 -- Number of spaces tabs count for
else
  vim.opt.shiftwidth = 4 -- Size of an indent
  vim.opt.tabstop = 4 -- Number of spaces tabs count for
end
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
vim.keymap.set(
  "n",
  "<leader>bd",
  function()
    local curbuf = vim.api.nvim_get_current_buf()
    local num_closed = 0
    for _, openbuf in ipairs(vim.api.nvim_list_bufs()) do
      if not vim.api.nvim_buf_is_loaded(openbuf) or vim.api.nvim_get_option_value("buftype", {buf = openbuf}) ~= "" then
        goto continue
      end
      if openbuf == curbuf then
        goto continue
      end
      vim.api.nvim_buf_delete(openbuf, {})
      num_closed = num_closed + 1
      ::continue::
    end
    print(num_closed .. " buffers closed")
  end,
  {desc = "Close all buffers except current"}
)

-- Nicer behavior for CTRL + o, CTRL + i.
vim.keymap.set("n", "<C-o>", "<C-o>zz")
vim.keymap.set("n", "<C-i>", "<C-i>zz")

vim.keymap.set({"n", "v"}, "<leader>y", '"+y', {desc = "Copy to system clipboard"})

vim.keymap.set({"n", "x"}, "c", '"_c', {desc = "Change without yanking"})
vim.keymap.set(
  "n",
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

vim.keymap.set("v", "gw", "y/\\V<C-R>=escape(@\",'/\')<cr><cr>N", {desc = "Search for visual selection"})
vim.keymap.set("v", "/", "o<esc>/\\%V", {desc = "Search within visual selection"})

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
