vim.opt.shiftwidth = 2     -- Size of an indent
vim.opt.tabstop = 2        -- Number of spaces tabs count for
vim.opt.expandtab = true   -- Use spaces instead of tabs
vim.opt.smartindent = true -- Insert indents automatically
vim.g.mapleader = " "
vim.opt.undofile = true
vim.opt.clipboard = "unnamedplus"
vim.opt.tags:append(".tags")

-- Set the directory where undo history will be stored
-- Using a dedicated path keeps your project folders clean
local undodir = vim.fn.stdpath("data") .. "/undo"
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end

vim.opt.undodir = undodir

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.textwidth = 80 -- Set your desired width here
    vim.opt_local.formatoptions:append("t") -- Auto-wrap text using textwidth
    vim.opt_local.wrap = true -- Soft wrap for visual comfort
    vim.opt_local.colorcolumn = "80"
  end,
})

vim.filetype.add({
  extension = {
    c3 = "c3",
    c3i = "c3",
    c3t = "c3",
  },
})


local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

local function mise_tasks_picker()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  -- Get mise tasks in JSON format
  local handle = io.popen("mise tasks ls -l --json")
  local result = handle:read("*a")
  handle:close()

  local tasks = vim.fn.json_decode(result)
  local task_names = {}
  for _, task in ipairs(tasks) do
    table.insert(task_names, task.name)
  end

  pickers.new({}, {
    prompt_title = "Mise Tasks",
    finder = finders.new_table({ results = task_names }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        -- Create terminal at bottom
        vim.cmd("botright split | term mise run " .. selection[1])
        -- Hide from buffer lists
        vim.api.nvim_buf_set_option(0, 'buflisted', false)
      end)
      return true
    end,
  }):find()
end

require("lazy").setup({
  -- Finder & Grepper
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup({
        pickers = {
          buffers = {
            mappings = {
              i = {
                ["<c-d>"] = "delete_buffer",
              },
            },
            ignore_current_buffer = true,
            sort_mru = true,
          },
        },
      })
    end,
  },

  -- Treesitter for Syntax Highlighting
  { 
    'nvim-treesitter/nvim-treesitter', 
    build = ':TSUpdate' ,
  },

  -- Auto-completion
  {
  "hrsh7th/nvim-cmp",
  dependencies = { 
    "hrsh7th/cmp-buffer",   -- Source for words in the current file
    "hrsh7th/cmp-path",     -- Source for file system paths
    "quangnguyen30192/cmp-nvim-tags",
  },
  config = function()
    local cmp = require("cmp")
    cmp.setup({
      mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(), -- Manually trigger
        ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept with Enter
        ['<Tab>'] = cmp.mapping.select_next_item(), -- Navigate with Tab
        ['<S-Tab>'] = cmp.mapping.select_prev_item(), -- Navigate with Shift+Tab
      }),
      sources = cmp.config.sources({
        { name = 'buffer' }, -- Suggests words from current file
        { name = 'path' },   -- Suggests file paths when typing /
        { name = 'tags' },   -- Suggests file paths when typing /
      })
    })
  end,
},

  {
    'stevearc/oil.nvim',
    opts = {},
    -- Optional: dependencies for icons
    dependencies = { "nvim-tree/nvim-web-devicons" }, 
  },

  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night", -- Choose from: "storm", "moon", "night", or "day"
      transparent = false, -- Set to true for a transparent background
      terminal_colors = true,
    },
  },
  {
    'numToStr/Comment.nvim',
    opts = {}
  },

  -- The popup menu for keybindings
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {}
  },

  {
    "mistweaverco/kulala.nvim",
    keys = {
    },
    ft = {"http", "rest"},
    opts = {
      global_keymaps = false,
      global_keymaps_prefix = "<leader>R",
      kulala_keymaps_prefix = "",
    },
  },


})


require'nvim-treesitter.configs'.setup {
  highlight = { 
    enable = true,
    additional_vim_regex_highlighting = true,
  },
  indent = { enable = true }, -- This powers the '=' operator with Treesitter
  auto_install = true,
}

local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.c3 = {
  install_info = {
    url = "https://github.com/c3lang/tree-sitter-c3", 
    files = { "src/parser.c", "src/scanner.c" }, 
    branch = "main",
  },
}



local wk = require("which-key")

wk.add({
  -- File Group
  { "<leader>f", group = "File" },
  { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File" },
  { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
  { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
  { "<leader>fm", function() require("conform").format({ async = true }) end, desc = "Format Buffer" },

  { "<leader>r", group = "REST / Kulala" },
  { "<leader>rr", function() require("kulala").run() end, desc = "Run Request" },
  { "<leader>rt", function() require("kulala").toggle_view() end, desc = "Toggle Body/Headers" },
  { "<leader>rp", function() require("kulala").jump_prev() end, desc = "Previous Request" },
  { "<leader>rn", function() require("kulala").jump_next() end, desc = "Next Request" },

  { "<leader>-", "<cmd>Oil<cr>", desc = "Open Parent Directory (Oil)" },
  { "<F5>", mise_tasks_picker, desc = "Mise Tasks" },
})




vim.cmd([[colorscheme tokyonight-moon]])
