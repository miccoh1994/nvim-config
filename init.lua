-- ─────────────────────────────────────────────────────────────────────────────
-- Bootstrap mini.nvim
-- ─────────────────────────────────────────────────────────────────────────────
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path    = path_package .. 'pack/deps/start/mini.nvim'
if not vim.uv.fs_stat(mini_path) then
  vim.cmd('echo "Installing mini.nvim…" | redraw')
  vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch', 'stable',
    'https://github.com/echasnovski/mini.nvim', mini_path })
  vim.cmd('packadd mini.nvim | helptags ALL')
end

require('mini.deps').setup({ path = { package = path_package } })
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

local _buf_char_for     = {}     -- buf_id → pick char
local _pick_mode_active = false  -- true while <leader>p picker is open

-- ─────────────────────────────────────────────────────────────────────────────
-- Options
-- ─────────────────────────────────────────────────────────────────────────────
now(function()
  vim.g.mapleader      = ' '
  vim.g.maplocalleader = '\\'

  local o = vim.opt
  o.number         = true
  o.relativenumber = true
  o.signcolumn     = 'yes'
  o.cursorline     = true
  o.wrap           = false
  o.scrolloff      = 8
  o.sidescrolloff  = 8
  o.tabstop        = 2
  o.shiftwidth     = 2
  o.expandtab      = true
  o.ignorecase     = true
  o.smartcase      = true
  o.splitbelow     = true
  o.splitright     = true
  o.termguicolors  = true
  o.undofile       = true
  o.updatetime     = 200
  o.pumheight      = 10
  o.completeopt    = 'menuone,noselect'
  o.clipboard      = 'unnamedplus'
  o.laststatus     = 3      -- global statusline
  o.showmode       = false  -- statusline shows mode instead
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Colorscheme
-- ─────────────────────────────────────────────────────────────────────────────
now(function()
  add({ source = 'ellisonleao/gruvbox.nvim' })
  vim.o.background = 'dark'
  vim.cmd.colorscheme('gruvbox')
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Core UI  (immediate – screen must look right on startup)
-- ─────────────────────────────────────────────────────────────────────────────
now(function()
  require('mini.icons').setup()

  require('mini.notify').setup()
  vim.notify = MiniNotify.make_notify()

  require('mini.statusline').setup({
    use_icons = true,
    content = {
      active = function()
        local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
        local git      = MiniStatusline.section_git({ trunc_width = 75 })
        local filename = MiniStatusline.section_filename({ trunc_width = 140 })
        local location = MiniStatusline.section_location({ trunc_width = 75 })

        local encoding = (vim.bo.fileencoding ~= '' and vim.bo.fileencoding or vim.o.encoding):lower()

        local diff = (function()
          local summary = vim.b.minidiff_summary
          if not summary then return '' end
          local n = (summary.add or 0) + (summary.delete or 0) + (summary.change or 0)
          return n > 0 and ('Δ ' .. n) or ''
        end)()

        local modified = vim.bo.modified and '* ' or ''
        local filetype = vim.bo.filetype ~= '' and (modified .. vim.bo.filetype) or ''

        return MiniStatusline.combine_groups({
          { hl = mode_hl,                  strings = { mode } },
          { hl = 'MiniStatuslineDevinfo',  strings = { git } },
          { hl = 'MiniStatuslineFilename', strings = { '❯', filename } },
          '%<',
          '%=',
          { hl = 'MiniStatuslineFileinfo', strings = { encoding } },
          { hl = 'MiniStatuslineDevinfo',  strings = { diff ~= '' and ('❮ ' .. diff) or '' } },
          { hl = 'MiniStatuslineFileinfo', strings = { filetype ~= '' and ('❮ ' .. filetype) or '' } },
          { hl = mode_hl,                  strings = { '%p%%', location } },
        })
      end,
    },
  })
  vim.api.nvim_set_hl(0, 'MiniTablinePickChar', { fg = '#fb4934', bold = true })

  -- Setup for highlight groups and autocmds; we override the string builder below
  require('mini.tabline').setup()

  MiniTabline.make_tabline_string = function()
    local bufs = vim.tbl_filter(function(b)
      return vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted
    end, vim.api.nvim_list_bufs())

    local cur = vim.api.nvim_get_current_buf()
    local s   = ''

    for _, buf in ipairs(bufs) do
      local is_cur = buf == cur
      local is_mod = vim.bo[buf].modified
      local hl     = is_cur
        and (is_mod and 'MiniTablineModifiedCurrent' or 'MiniTablineCurrent')
        or  (is_mod and 'MiniTablineModifiedHidden'  or 'MiniTablineHidden')
      local char   = _buf_char_for[buf]
      local name   = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t')
      if name == '' then name = '[No Name]' end

      local icon = ''
      if _G.MiniIcons then
        local ok, ic = pcall(MiniIcons.get, 'file', name)
        if ok then icon = ic .. ' ' end
      end

      local label  = name:gsub('%%', '%%%%')  -- escape % in filenames
      local suffix = is_mod and ' ●' or ''

      if _pick_mode_active and char then
        s = s .. '%#MiniTablinePickChar#' .. char .. '%#' .. hl .. '# ' .. icon .. label .. suffix .. ' '
      else
        s = s .. '%#' .. hl .. '# ' .. icon .. label .. suffix .. ' '
      end
    end

    return s .. '%#MiniTablineFill#'
  end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Sensible defaults (options, window maps, <C-s>, alt-move wiring)
-- ─────────────────────────────────────────────────────────────────────────────
now(function()
  require('mini.basics').setup({
    options      = { extra_ui = true },
    mappings     = { windows = true, move_with_alt = true },
    autocommands = { relnum_in_visual_mode = true },
  })

  -- Clear search highlight
  vim.keymap.set('n', '<Esc>', '<Cmd>nohlsearch<CR>', { desc = 'Clear hlsearch' })
  -- Toggle between current and last buffer
  vim.keymap.set('n', '<BS>', '<C-^>', { desc = 'Toggle last buffer' })
  -- Escape from insert mode
  vim.keymap.set('i', 'jj', '<Esc>', { desc = 'Escape insert mode' })
  -- Diagnostics
  vim.keymap.set('n', 'E',           vim.diagnostic.open_float, { desc = 'Diagnostic float' })
  vim.keymap.set('n', '<leader>dj',  vim.diagnostic.goto_next,  { desc = 'Next diagnostic' })
  vim.keymap.set('n', '<leader>dk',  vim.diagnostic.goto_prev,  { desc = 'Prev diagnostic' })
  -- Split navigation
  vim.keymap.set('n', '<leader>h', '<C-w>h', { desc = 'Focus left split' })
  vim.keymap.set('n', '<leader>j', '<C-w>j', { desc = 'Focus down split' })
  vim.keymap.set('n', '<leader>k', '<C-w>k', { desc = 'Focus up split' })
  vim.keymap.set('n', '<leader>l', '<C-w>l', { desc = 'Focus right split' })
  -- Quick-close
  vim.keymap.set('n', '<leader>q', '<Cmd>q<CR>',  { desc = 'Quit' })
  vim.keymap.set('n', '<leader>Q', '<Cmd>qa!<CR>', { desc = 'Quit all' })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Key clue (which-key style hints)
-- ─────────────────────────────────────────────────────────────────────────────
later(function()
  local clue = require('mini.clue')
  clue.setup({
    window = { delay = 200 },
    triggers = {
      { mode = 'n', keys = '<Leader>' },
      { mode = 'x', keys = '<Leader>' },
      { mode = 'n', keys = 'g' },
      { mode = 'n', keys = "'" },
      { mode = 'n', keys = '`' },
      { mode = 'n', keys = '"' },
      { mode = 'i', keys = '<C-r>' },
      { mode = 'n', keys = '<C-w>' },
      { mode = 'n', keys = 'z' },
      { mode = 'n', keys = '[' },
      { mode = 'n', keys = ']' },
    },
    clues = {
      { mode = 'n', keys = '<Leader>b', desc = '+buffers' },
      { mode = 'n', keys = '<Leader>d', desc = '+diagnostics' },

      { mode = 'n', keys = '<Leader>f', desc = '+find' },
      { mode = 'n', keys = '<Leader>g', desc = '+git' },
      { mode = 'n', keys = '<Leader>L', desc = '+lsp' },
      { mode = 'n', keys = '<Leader>s', desc = '+search' },
      { mode = 'n', keys = '<Leader>S', desc = '+sessions' },
      clue.gen_clues.builtin_completion(),
      clue.gen_clues.g(),
      clue.gen_clues.marks(),
      clue.gen_clues.registers(),
      clue.gen_clues.windows(),
      clue.gen_clues.z(),
    },
  })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Files & pickers
-- ─────────────────────────────────────────────────────────────────────────────
later(function()
  require('mini.files').setup({ windows = { preview = true, width_preview = 50 } })
  require('mini.pick').setup({ window = { prompt_prefix = '  ' } })
  require('mini.extra').setup()
  require('mini.visits').setup()
  require('mini.bufremove').setup()

  local map = vim.keymap.set
  -- Explorer (toggle: close if open, open at current file if closed)
  map('n', '<leader>e', function()
    if not MiniFiles.close() then
      MiniFiles.open(vim.api.nvim_buf_get_name(0))
    end
  end, { desc = 'Toggle explorer' })
  map('n', '<leader>E', function() MiniFiles.open() end, { desc = 'Explorer (cwd)' })
  -- Search
  map('n', '<leader>sf', function() MiniPick.builtin.files({ tool = 'rg' }) end,          { desc = 'Search files (rg)' })
  map('n', '<leader>sg', function() MiniPick.builtin.grep_live({ tool = 'rg' }) end,    { desc = 'Search grep (rg)' })
  -- Find (extras)
  map('n', '<leader>fb', function() MiniPick.builtin.buffers() end,                     { desc = 'Buffers' })
  map('n', '<leader>fh', function() MiniPick.builtin.help() end,                        { desc = 'Help' })
  map('n', '<leader>fr', function() MiniExtra.pickers.visit_paths() end,                { desc = 'Recent (visits)' })
  map('n', '<leader>fo', function() MiniExtra.pickers.oldfiles() end,                   { desc = 'Old files' })
  map('n', '<leader>fd', function() MiniExtra.pickers.diagnostic() end,                 { desc = 'Diagnostics' })
  map('n', '<leader>fk', function() MiniExtra.pickers.keymaps() end,                    { desc = 'Keymaps' })
  -- Buffer pick: assign chars and rebuild on buffer list changes
  local function refresh_buf_chars()
    for k in pairs(_buf_char_for) do _buf_char_for[k] = nil end
    local bufs = vim.tbl_filter(function(b)
      return vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted
    end, vim.api.nvim_list_bufs())
    local used = {}
    for _, buf in ipairs(bufs) do
      local stem = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t:r'):lower()
      local char
      for i = 1, #stem do
        local c = stem:sub(i, i)
        if c:match('[a-z]') and not used[c] then char = c; break end
      end
      if not char then
        for c in ('abcdefghijklmnopqrstuvwxyz'):gmatch('.') do
          if not used[c] then char = c; break end
        end
      end
      if char then used[char] = true; _buf_char_for[buf] = char end
    end
  end
  refresh_buf_chars()
  vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete', 'BufWipeout', 'BufFilePost' }, {
    callback = vim.schedule_wrap(refresh_buf_chars),
  })

  -- <leader>p: show chars on tabs, wait for keypress, jump, hide chars
  map('n', '<leader>p', function()
    _pick_mode_active = true
    vim.cmd('redrawtabline')
    local ok, char = pcall(vim.fn.getcharstr)
    _pick_mode_active = false
    vim.cmd('redrawtabline')
    if not ok then return end
    for buf, c in pairs(_buf_char_for) do
      if c == char then vim.api.nvim_set_current_buf(buf); return end
    end
  end, { desc = 'Pick buffer' })
  map('n', '<leader>bd', function() MiniBufremove.delete() end,        { desc = 'Delete buffer' })
  map('n', '<leader>bD', function() MiniBufremove.delete(0, true) end, { desc = 'Delete buffer (force)' })
  map('n', '<leader>bci', function()
    local visible = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      visible[vim.api.nvim_win_get_buf(win)] = true
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and not visible[buf] then
        MiniBufremove.delete(buf, false)
      end
    end
  end, { desc = 'Close inactive buffers' })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Sessions
-- ─────────────────────────────────────────────────────────────────────────────
later(function()
  require('mini.sessions').setup({
    autowrite = true,
    directory = vim.fn.stdpath('data') .. '/sessions/',
    file      = '',
  })

  -- Build a session name from git root (dirname) + branch, e.g. "my-app__feat-login"
  local function session_name()
    local root   = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('%s+', '')
    local branch = vim.fn.system('git rev-parse --abbrev-ref HEAD 2>/dev/null'):gsub('%s+', '')
    if root == '' then root = vim.fn.getcwd() end
    local project = vim.fn.fnamemodify(root, ':t')
    branch = branch:gsub('[/\\:]', '-')  -- make filesystem-safe
    return branch ~= '' and (project .. '__' .. branch) or project
  end

  -- Auto-load matching session when Neovim opens with no file arguments
  if vim.fn.argc() == 0 then
    local name = session_name()
    if MiniSessions.detected[name] then
      MiniSessions.read(name)
    end
  end

  local map = vim.keymap.set
  map('n', '<leader>Sw', function() MiniSessions.write(session_name()) end, { desc = 'Write session' })
  map('n', '<leader>Sr', function() MiniSessions.select('read') end,        { desc = 'Restore session' })
  map('n', '<leader>Sd', function() MiniSessions.select('delete') end,      { desc = 'Delete session' })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Editing
-- ─────────────────────────────────────────────────────────────────────────────
later(function()
  require('mini.comment').setup()   -- gcc / gc
  require('mini.pairs').setup()     -- auto-close brackets
  require('mini.surround').setup()  -- sa / sd / sr
  require('mini.ai').setup({ n_lines = 500 })  -- better a/i text objects
  require('mini.move').setup()      -- <M-hjkl> move lines / selections
  require('mini.operators').setup() -- gr (replace), gs (sort), gm (duplicate), g= (eval)
  require('mini.trailspace').setup()

  require('mini.indentscope').setup({
    symbol  = '│',
    options = { try_as_border = true },
  })

  require('mini.cursorword').setup()

  require('mini.hipatterns').setup({
    highlighters = {
      fixme     = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'DiagnosticError' },
      hack      = { pattern = '%f[%w]()HACK()%f[%W]',  group = 'DiagnosticWarn' },
      todo      = { pattern = '%f[%w]()TODO()%f[%W]',  group = 'DiagnosticInfo' },
      note      = { pattern = '%f[%w]()NOTE()%f[%W]',  group = 'DiagnosticHint' },
      hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
    },
  })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Git
-- ─────────────────────────────────────────────────────────────────────────────
later(function()
  require('mini.diff').setup()  -- diff signs in sign column
  require('mini.git').setup()   -- git integration + blame

  local map = vim.keymap.set
  map('n', '<leader>go', MiniDiff.toggle_overlay,  { desc = 'Diff overlay' })
  map('n', '<leader>gs', MiniGit.show_at_cursor,   { desc = 'Show at cursor' })
  map('n', '<leader>gS', function() MiniExtra.pickers.git_hunks() end,   { desc = 'Git hunks' })
  map('n', '<leader>gb', function() MiniExtra.pickers.git_branches() end, { desc = 'Git branches' })
  map('n', '<leader>gc', function() MiniExtra.pickers.git_commits() end,  { desc = 'Git commits' })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- LSP + Completion
-- ─────────────────────────────────────────────────────────────────────────────
later(function()
  add({ source = 'neovim/nvim-lspconfig' })
  add({ source = 'williamboman/mason.nvim' })
  add({ source = 'williamboman/mason-lspconfig.nvim' })

  -- Set capabilities globally — picked up by every server
  vim.lsp.config('*', {
    capabilities = vim.lsp.protocol.make_client_capabilities(),
  })

  require('mason').setup()
  require('mason-lspconfig').setup({
    handlers = {
      function(server_name) vim.lsp.enable(server_name) end,
    },
  })

  require('mini.snippets').setup()
  require('mini.completion').setup()

  vim.diagnostic.config({
    virtual_text     = { prefix = '●' },
    signs            = true,
    underline        = true,
    update_in_insert = false,
    severity_sort    = true,
    float            = { border = 'rounded', source = 'always' },
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(ev)
      local map = function(keys, fn, desc)
        vim.keymap.set('n', keys, fn, { buffer = ev.buf, desc = desc })
      end
      -- Navigation
      map('gd', vim.lsp.buf.definition,      'Definition')
      map('gD', vim.lsp.buf.declaration,     'Declaration')
      map('gR', vim.lsp.buf.references,      'References')  -- uppercase: gr is mini.operators replace
      map('gi', vim.lsp.buf.implementation,  'Implementation')
      map('gy', vim.lsp.buf.type_definition, 'Type definition')
      map('K',  vim.lsp.buf.hover,           'Hover docs')
      -- Actions
      map('<leader>rn', vim.lsp.buf.rename,      'Rename')
      map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
      map('<leader>Lf', function() vim.lsp.buf.format({ async = true }) end, 'Format')
      -- Diagnostics
      map('[d', vim.diagnostic.goto_prev,  'Prev diagnostic')
      map(']d', vim.diagnostic.goto_next,  'Next diagnostic')
      map('<leader>d', vim.diagnostic.open_float, 'Diagnostic float')
      -- Symbols via mini.extra
      map('<leader>Ls', function() MiniExtra.pickers.lsp({ scope = 'document_symbol' }) end,  'Document symbols')
      map('<leader>LS', function() MiniExtra.pickers.lsp({ scope = 'workspace_symbol' }) end, 'Workspace symbols')
      map('<leader>Lm', '<Cmd>Mason<CR>', 'Mason')
    end,
  })


end)
