call plug#begin()
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-nvim-lsp-signature-help'
Plug 'navarasu/onedark.nvim'
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'nvim-telescope/telescope-file-browser.nvim'
Plug 'folke/trouble.nvim'
Plug 'hoob3rt/lualine.nvim'
Plug 'airblade/vim-rooter'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'nvim-treesitter/playground'
Plug 'neoclide/vim-jsx-improve'
Plug 'JoosepAlviste/nvim-ts-context-commentstring'
Plug 'terrortylor/nvim-comment'
Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'danymat/neogen'
call plug#end()

" -----------------------------------------------------------------------------
" My settings

" Set leader key to '\'.
let g:mapleader='\'

" Enable filetype detection.
filetype plugin indent on
" Enable syntax hightlighting.
syntax on
" Hide alternate buffers instead of closing them. Required for cross-buffer autocomplete.
set hidden

" Always try to show 10 lines above and below the cursor.
set scrolloff=10
" Hitting tab while in command line mode shows options.
set wildmenu
" Case insensitive file open.
set wildignorecase
" In INSERT mode, F2 to enter PASTE mode (for large pastes).
set pastetoggle=<F2>
" Instead of stumbling into ex mode, repeat the last macro used.
nnoremap Q @@
" Highlight these words as if they were TODO.
match Todo "NOTE"

" Tab and backspace delete full indenation.
set smarttab
" Backspace deletes indents, newlines.
set backspace=indent,eol,start
" Tab adds spaces instead of \t.
set expandtab
" Tab should be 4 spaces.
set tabstop=4
" Auto indentation should be 4 spaces.
set shiftwidth=4

autocmd FileType lua setlocal tabstop=2 shiftwidth=2

" Text searching ignores case unless an upper case letter is present.
set ignorecase smartcase
" Begin text searching while typing, hightlighting matches.
set incsearch hlsearch
" Enter clears search highlights. Note that this also prevents enter from moving
" cursor down a line.
nnoremap <silent> <CR> :noh<CR>

" In split buffers, Ctrl + [JKLH] to navigate.
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
" Buffer split more naturally
set splitbelow
set splitright

" Space = go down 10 lines, CTRL + Space = go up 10 lines.
nnoremap <Space> 10j
nnoremap <C-Space> 10k
vnoremap <Space> 10j
vnoremap <C-Space> 10k
" Go to next row in editor instead of next line (for wrapped lines).
nnoremap j gj
nnoremap k gk


" Format options here affect code comments. See :h fo-table for more details.
" Set default text width. Vim will automatically start a new line when comment text goes above this
" number. Note that we specify file extensions here because we don't want this behavior in every
" file (e.g. .txt or .md files).
autocmd BufNewFile,BufRead *.js,*.jsx,*.ts,*.tsx,*.java,*.css,*.scss,*.sh,*.rb,*.rs,*.vim,*.lua setlocal textwidth=100
" Don't automatically format single line comments. Vim will automatically add the comment token to
" your newline if the previous line started with a comment token. This can be annoying when you want
" to write a single comment line then go back to writing code.
autocmd BufNewFile,BufRead * setlocal formatoptions-=ro formatoptions+=p
" autocmd FileType java,javascript,javascriptreact,typescript,typescriptreact setlocal comments-=:// comments+=f://
" Don't auto-wrap text in gitcommits. Typically, I don't want any special actions for git commits.
autocmd FileType gitcommit setlocal formatoptions-=tl

" Press ESC to enter normal mode in terminal mode. Terminal mode can be accessed by running :term
tnoremap <Esc> <C-\><C-n>
nnoremap vp `[v`]

nnoremap \sb <cmd>%s/\({\\|\[\) /\1/gc<cr>
nnoremap \se <cmd>%s/\(\S\) \(}\\|\]\)/\1\2/gc<cr>

" Coloring
" set background=dark
" set termguicolors
try
    colorscheme onedark
catch /^Vim\%((\a\+)\)\=:E185/
    " Just use the default then
endtry

" -----------------------------------------------------------------------------
" General Lua helpers
lua <<EOF
function is_module_available(name)
    if package.loaded[name] then
        return true
    else
        for _, searcher in ipairs(package.searchers or package.loaders) do
            local loader = searcher(name)
            if type(loader) == 'function' then
                package.preload[name] = loader
                return true
            end
        end
        return false
    end
end
_G.is_module_available = is_module_available
EOF


" -----------------------------------------------------------------------------
" luasnip
lua <<EOF
if not is_module_available("luasnip") then
    return
end
local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt

ls.config.setup({
    region_check_events = "CursorMoved",
    delete_check_events = "TextChanged",
})

-- vim.api.nvim_set_keymap("s", "nn", "<cmd>lua require('luasnip').jump(1)<CR>", {noremap = true, silent = true})
-- vim.api.nvim_set_keymap("n", "nn", "<cmd>lua require('luasnip').jump(1)<CR>", {noremap = true, silent = true})
local replace_termcodes = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

_G.luasnip_jump_next = function()
    if ls.jumpable(1) then
        return replace_termcodes("<Plug>luasnip-jump-next")
    else
        return replace_termcodes("<C-j>")
    end
end

_G.luasnip_jump_prev = function()
    if ls.jumpable(-1) then
        return replace_termcodes("<Plug>luasnip-jump-prev")
    else
        return replace_termcodes("<C-k>")
    end
end

vim.api.nvim_set_keymap("s", "<C-j>", "v:lua.luasnip_jump_next()", {expr = true})
vim.api.nvim_set_keymap("i", "<C-j>", "v:lua.luasnip_jump_next()", {expr = true})
vim.api.nvim_set_keymap("s", "<C-k>", "v:lua.luasnip_jump_prev()", {expr = true})
vim.api.nvim_set_keymap("i", "<C-k>", "v:lua.luasnip_jump_prev()", {expr = true})

ls.add_snippets("typescriptreact", {
    ls.snippet(
        {trig = "heading", name = "heading JSX"},
        fmt(
            "<Heading level={{{level}}}>{text}</Heading>",
            {
                level = ls.insert_node(1, "level"),
                text = ls.insert_node(0, "text"),
            }
        )
    ),
    ls.snippet(
        {trig = "paragraph", name = "paragraph JSX"},
        fmt(
            "<p>\n\t{text}\n</p>",
            {text = ls.insert_node(0, "text")}
        )
    ),
    ls.snippet(
        {trig = "div", name = "div JSX"},
        fmt(
            "<div>\n\t{text}\n</div>",
            {text = ls.insert_node(0, "text")}
        )
    ),
    ls.snippet(
        {trig = "code", name = "code JSX"},
        fmt(
            "<code>{text}</code>",
            {
                text = ls.insert_node(0, "text"),
            }
        )
    ),
    ls.snippet(
        {trig = "ul", name = "ul JSX"},
        fmt(
            "<ul>\n\t{children}\n</ul>",
            {children = ls.insert_node(0)}
        )
    ),
    ls.snippet(
        {trig = "li", name = "li JSX"},
        fmt(
            "<li>\n\t{text}\n</li>",
            {text = ls.insert_node(0, "text")}
        )
    ),
    ls.snippet(
        {trig ="import", name = "import statement"},
        fmt(
            "import {module} from \"{file}\";",
            {
                module = ls.insert_node(1, "module"),
                file = ls.insert_node(0, "file"),
            }
        )
    ),
})
EOF

" -----------------------------------------------------------------------------
" neogen
lua <<EOF
require("neogen").setup({snippet_engine = "luasnip"})

vim.api.nvim_set_keymap("n", "<Leader>dc", ":lua require('neogen').generate({type = 'class'})<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap("n", "<Leader>df", ":lua require('neogen').generate({type = 'func'})<CR>", {noremap = true, silent = true})
EOF

" -----------------------------------------------------------------------------
" nvim-cmp
" These settings are partially derived from here:
" https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings#no-snippet-plugin

set completeopt=menuone,noselect

lua <<EOF
local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
end
if not is_module_available("luasnip") or not is_module_available("cmp") then
    return
end
local luasnip = require("luasnip")
local cmp = require("cmp")
cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end
    },
    mapping = {
        ["<cr>"] = cmp.mapping.confirm(),
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
        end, {"i"}),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, {"i"}),
        ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), {"i", "c"}),
        ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), {"i", "c"}),
    },
    sources = cmp.config.sources({
        {name = "nvim_lsp"},
        {name = "luasnip"},
        {
            name = "buffer",
            -- option = {
            --     get_bufnrs = function()
            --         return vim.api.nvim_list_bufs()
            --     end,
            -- },
        },
        {name = "path"},
        {name = "nvim_lsp_signature_help"},
    }),
    flags = {
        debounce_text_changes = 150,
    },
})
EOF

" Disable autocomplete in Telescope windows.
autocmd FileType TelescopePrompt lua require("cmp").setup.buffer({completion = {autocomplete = false}})

" -----------------------------------------------------------------------------
" nvim-lspconfig
lua <<EOF
if not is_module_available("lspconfig") then
    return
end
local lspconfig = require("lspconfig")
local util = lspconfig.util

local eslint_d = {
    lintCommand = "eslint_d -f unix --stdin --stdin-filename ${INPUT}",
    lintStdin = true,
    lintFormats = {"%f:%l:%c: %m"},
    lintIgnoreExitCode = true,
}

lspconfig.efm.setup({
    init_options = {documentFormatting = true},
    filetypes = {"javascript", "javascriptreact"},
    root_dir = function(fname)
        return util.root_pattern(".eslintrc.js", ".git", ".bashrc")(fname);
    end,
    settings = {
        rootMarkers = {".git/", ".eslintrc", ".bashrc"},
        lintDebounce = "500ms",
        languages = {
            javascript = {eslint_d},
            javascriptreact = {eslint_d},
        }
    }
})

lspconfig.tsserver.setup({
    filetypes = {"typescript", "typescriptreact", "typescript.jsx"},
    settings = {
        diagnostics = {
            -- https://github.com/microsoft/TypeScript/blob/main/src/compiler/diagnosticMessages.json
            ignoredCodes = {
                80006,
            },
        },
    },
})

lspconfig.jdtls.setup({
    cmd = {"jdtls"},
    filetypes = {"java"},
    root_dir = function(fname)
        return util.root_pattern("build.xml")(fname)
    end,
    settings = {
        java = {
            project = {
                referencedLibraries = {
                    "lib/**/*.jar",
                    "ivylib/**/*.jar",
                    "main/bin/**/*.jar",
                    "test/bin/**/*.jar",
                },
                sourcePaths = {
                    "main",
                    "test",
                }
            }
        }
    }
})
vim.lsp.set_log_level("info")
EOF

nnoremap <C-n> <cmd>lua vim.diagnostic.goto_next({popup_opts = {focusable = false}})<cr>
nnoremap <C-b> <cmd>lua vim.diagnostic.goto_prev({popup_opts = {focusable = false}})<cr>
nnoremap gD <cmd>lua vim.lsp.buf.declaration()<cr>
nnoremap gd <cmd>lua vim.lsp.buf.definition()<cr>
nnoremap K <cmd>lua vim.lsp.buf.hover()<cr>
" nnoremap gr <cmd>lua vim.lsp.buf.references()<cr>

" -----------------------------------------------------------------------------
" nvim-telescope
lua <<EOF
if not is_module_available("nvim-web-devicons") or not is_module_available("telescope") then
    return
end
require("nvim-web-devicons").setup({
  default = true
})
local telescope = require("telescope")
telescope.setup({
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
        }
    },
    defaults = {
        cache_picker = {
            num_pickers = 20
        },
    },
})
telescope.load_extension("fzf")
telescope.load_extension("file_browser")
EOF

let g:rooter_manual_only = 1
let g:rooter_patterns = [ '.git', '.svn', '.bashrc', '.bash_profile' ]
nnoremap <expr> <C-p> ':Telescope find_files cwd=' . FindRootDirectory() . '/ hidden=true<cr>'
nnoremap <C-o> <cmd>Telescope live_grep<cr>
nnoremap <C-i> <cmd>Telescope file_browser<cr>
nnoremap <C-u> <cmd>Telescope buffers<cr>
nnoremap <C-y> <cmd>Telescope pickers<cr>

" -----------------------------------------------------------------------------
" nvim-trouble
" lua require('init_trouble')
lua <<EOF
if not is_module_available("trouble") then
    return
end
require("trouble").setup({
    action_keys = {
        close = "<esc>"
    }
})
EOF

nnoremap gr <cmd>TroubleToggle lsp_references<cr>
" nnoremap <leader>xx <cmd>TroubleToggle<cr>
" nnoremap <leader>xd <cmd>TroubleToggle document_diagnostics<cr>
" nnoremap <leader>xr <cmd>TroubleToggle lsp_references<cr>

" -----------------------------------------------------------------------------
" lualine
lua require("lualine").setup({options = {theme = "onedark"}})

" -----------------------------------------------------------------------------
" nvim-treesitter
lua <<EOF
if not is_module_available("nvim-treesitter") then
    return
end
require("nvim-treesitter.configs").setup({
    ensure_installed = "all",
    highlight = {
        enable = true,
    },
    indent = {
        enable = true,
        -- disable = { "javascriptreact", "javascript", "jsx" },
    },
    context_commentstring = {
        enable = true,
        config = {
            scss = { __default = '// %s', __multiline = '/* %s */' },
        },
    },
    playground = {
        enable = true,
    },
})
EOF

" -----------------------------------------------------------------------------
" tcomment_vim
" let g:tcomment_opleader1 = "f"
" let g:tcomment#filetype#guess_javascriptreact = 1
" " ff: toggle comment for current line.
" nnoremap <silent> ff :TComment<cr>
" " fp: toggle comment for current paragraph.
" nnoremap <silent> fp mpvip:TComment<cr>`p
" " fb: toggle block comment in visual mode.
" vnoremap <silent> fb :TCommentBlock<cr>

" -----------------------------------------------------------------------------
" nvim-comment

lua <<EOF
if not is_module_available("nvim_comment") then
    return
end
require("nvim_comment").setup({
    operator_mapping = "f",
    hook = function()
        require("ts_context_commentstring.internal").update_commentstring()
    end,
})
EOF

" ff: toggle comment for current line.
nnoremap <silent> ff :CommentToggle<cr>
" fp: toggle comment for current paragraph.
nnoremap <silent> fp vip:CommentToggle<cr>
" nnoremap <silent> fp mtgcip`t

