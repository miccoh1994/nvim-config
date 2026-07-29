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
      { mode = 'n', keys = '<Leader>m', desc = '+markdown' },
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

  -- ── Explorer: lock navigation to the project root ──────────────────────────
  -- Track the root (git root, else cwd) set when the explorer opens, and make
  -- `h` / `H` refuse to climb above it.
  local mf_root
  local function mf_set_root(path)
    local start = (path and path ~= '') and path or vim.uv.cwd()
    mf_root = vim.fs.normalize(vim.fs.root(start, '.git') or vim.uv.cwd())
  end
  local function mf_at_root()
    local st = MiniFiles.get_explorer_state()
    local w  = st and st.windows[st.depth_focus]
    return w ~= nil and mf_root ~= nil and vim.fs.normalize(w.path) == mf_root
  end
  local function mf_go_out()
    if mf_at_root() then return end
    MiniFiles.go_out()
  end
  local function mf_go_out_plus()
    if mf_at_root() then return end
    MiniFiles.go_out()
    MiniFiles.trim_right()
  end

  -- Override go-out in each explorer buffer + advertise the CRUD workflow in a
  -- footer (create/rename/delete are done by editing the buffer, then `=`).
  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesBufferCreate',
    callback = function(args)
      local opts = { buffer = args.data.buf_id, nowait = true }
      vim.keymap.set('n', 'h', mf_go_out,      vim.tbl_extend('force', opts, { desc = 'Go out (≤ root)' }))
      vim.keymap.set('n', 'H', mf_go_out_plus, vim.tbl_extend('force', opts, { desc = 'Go out + (≤ root)' }))
    end,
  })
  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesWindowUpdate',
    callback = function(args)
      local win = args.data.win_id
      local cfg = vim.api.nvim_win_get_config(win)
      local st  = MiniFiles.get_explorer_state()
      local focused = st and st.windows[st.depth_focus] and st.windows[st.depth_focus].win_id
      cfg.footer = win == focused and { { ' new line=add · edit=rename · dd=delete · = apply · g? ', 'MiniFilesTitle' } } or ''
      cfg.footer_pos = win == focused and 'left' or nil
      vim.api.nvim_win_set_config(win, cfg)
    end,
  })

  require('mini.pick').setup({ window = { prompt_prefix = '  ' } })

  -- Make terminal paste (e.g. Cmd+V) insert into the picker prompt.
  -- mini.pick's setup() replaces vim.paste with a no-op hint while a picker is
  -- active; re-wrap it here so a bracketed paste appends to the query instead.
  local paste_when_no_picker = vim.paste
  vim.paste = function(lines, phase)
    if not MiniPick.is_picker_active() then
      return paste_when_no_picker(lines, phase)
    end
    local query = MiniPick.get_picker_query()
    for _, ch in ipairs(vim.fn.split(table.concat(lines, ' '), '\\zs')) do
      table.insert(query, ch)
    end
    MiniPick.set_picker_query(query)
    return true
  end

  require('mini.extra').setup()
  require('mini.visits').setup()
  require('mini.bufremove').setup()

  local map = vim.keymap.set
  -- Explorer (toggle: close if open, open at current file if closed)
  map('n', '<leader>e', function()
    if not MiniFiles.close() then
      local path = vim.api.nvim_buf_get_name(0)
      mf_set_root(path)
      MiniFiles.open(path)
    end
  end, { desc = 'Toggle explorer' })
  map('n', '<leader>E', function() mf_set_root(vim.uv.cwd()); MiniFiles.open(vim.uv.cwd()) end, { desc = 'Explorer (cwd)' })
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
  -- gr is reserved for LSP references (see LspAttach); move replace to gR
  require('mini.operators').setup({ replace = { prefix = 'gR' } }) -- gR (replace), gs (sort), gm (duplicate), g= (eval)
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

  -- Peek a symbol's definition in a floating window instead of jumping/splitting
  local function peek_definition()
    local client = vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/definition' })[1]
    if not client then return end
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    client:request('textDocument/definition', params, function(err, result)
      if err or not result or vim.tbl_isempty(result) then
        return vim.notify('No definition found', vim.log.levels.INFO)
      end
      local location = result[1] or result
      vim.lsp.util.preview_location(location, { border = 'rounded', focusable = true })
    end)
  end

  -- Goto definition: jump straight there if there's one result, else show a picker
  local function goto_definition()
    local client = vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/definition' })[1]
    if not client then return end
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    client:request('textDocument/definition', params, function(err, result)
      if err or not result or vim.tbl_isempty(result) then
        return vim.notify('No definition found', vim.log.levels.INFO)
      end
      local locations = vim.islist(result) and result or { result }
      if #locations == 1 then
        vim.lsp.util.show_document(locations[1], client.offset_encoding, { focus = true })
      else
        MiniExtra.pickers.lsp({ scope = 'definition' })
      end
    end)
  end

  -- Neovim ships global gr* LSP defaults (grr/gra/grn/gri/grt/grx). They make
  -- our immediate `gr` (references) a prefix, so Neovim waits and mini.clue
  -- shows a menu. Remove them — this config binds the equivalents elsewhere.
  for _, lhs in ipairs({ 'grn', 'gra', 'grr', 'gri', 'grt', 'grx' }) do
    pcall(vim.keymap.del, 'n', lhs)
  end

  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(ev)
      local map = function(keys, fn, desc)
        vim.keymap.set('n', keys, fn, { buffer = ev.buf, desc = desc })
      end
      -- Navigation
      map('gd', goto_definition,             'Goto definition')
      map('gD', peek_definition,             'Peek definition')
      map('gr', function() MiniExtra.pickers.lsp({ scope = 'references' }) end, 'References')  -- replace operator moved to gR
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

-- ─────────────────────────────────────────────────────────────────────────────
-- Markdown
-- ─────────────────────────────────────────────────────────────────────────────
-- Languages highlighted inside fenced code blocks, using Neovim's bundled
-- syntax files (see the highlighter note in markdown_buf_setup below). Must be
-- set before a markdown buffer loads its syntax, hence `now()`. Entries are
-- either a filetype or `alias=filetype`.
--
-- Each entry sources a syntax file the first time a markdown buffer highlights,
-- so this list is a latency/coverage trade: ~35ms for markdown alone, ~70ms with
-- the list below. The costly ones left out are java (+30ms), html (+20ms),
-- vim/rust (+15ms each) and css (+14ms).
now(function()
  vim.g.markdown_fenced_languages = {
    'bash=sh', 'sh', 'zsh', 'c', 'cpp', 'diff', 'dockerfile', 'go',
    'javascript', 'js=javascript', 'json', 'jsonc', 'lua', 'make',
    'python', 'py=python', 'sql', 'toml', 'typescript', 'ts=typescript',
    'yaml', 'yml=yaml',
  }
end)

later(function()
  -- ── Gruvbox-tuned colours for the RenderMarkdown* groups ───────────────────
  -- The plugin defines these with `default = true`, so explicit sets win.
  -- `:colorscheme` clears them, so re-apply on ColorScheme; the autocmd is
  -- registered *before* the plugin loads so it runs first and the plugin can
  -- rebuild its derived (blended) groups from these values.
  local function markdown_colors()
    local set = function(name, opts) vim.api.nvim_set_hl(0, name, opts) end

    -- heading level → { accent fg, accent blended ~18% into gruvbox bg0 }
    local levels = {
      { '#fb4934', '#4e2e2a' },  -- red
      { '#fe8019', '#4e3825' },  -- orange
      { '#fabd2f', '#4e4329' },  -- yellow
      { '#b8bb26', '#424328' },  -- green
      { '#8ec07c', '#3a4337' },  -- aqua
      { '#d3869b', '#47393d' },  -- purple
    }
    for i, c in ipairs(levels) do
      set('RenderMarkdownH' .. i,         { fg = c[1], bold = true })
      set('RenderMarkdownH' .. i .. 'Bg', { fg = c[1], bg = c[2], bold = true })
    end

    -- Code blocks sit on bg0_s so they read as cards against Normal (#282828)
    set('RenderMarkdownCode',         { bg = '#32302f' })
    set('RenderMarkdownCodeBorder',   { bg = '#32302f' })
    set('RenderMarkdownCodeInfo',     { fg = '#928374', bg = '#32302f', italic = true })
    set('RenderMarkdownCodeFallback', { fg = '#a89984', bg = '#32302f' })
    set('RenderMarkdownCodeInline',   { fg = '#fe8019', bg = '#3c3836' })

    set('RenderMarkdownBullet',    { fg = '#fe8019' })
    set('RenderMarkdownDash',      { fg = '#504945' })
    set('RenderMarkdownTableHead', { fg = '#d3869b', bold = true })
    set('RenderMarkdownTableRow',  { fg = '#83a598' })
    set('RenderMarkdownLink',      { fg = '#8ec07c' })
    set('RenderMarkdownLinkTitle', { fg = '#83a598', underline = true })
    set('RenderMarkdownWikiLink',  { fg = '#8ec07c' })
    set('RenderMarkdownUnchecked', { fg = '#928374' })
    set('RenderMarkdownChecked',   { fg = '#b8bb26' })
    set('RenderMarkdownTodo',      { fg = '#fabd2f' })
    set('RenderMarkdownIndent',    { fg = '#3c3836' })
    set('RenderMarkdownHtmlComment', { fg = '#665c54', italic = true })
    -- ==highlighted== text, marker-pen style
    set('RenderMarkdownInlineHighlight', { fg = '#282828', bg = '#fabd2f' })

    -- Block quote bars cycle by nesting level
    local quotes = { '#8ec07c', '#83a598', '#d3869b', '#b8bb26', '#fabd2f', '#fe8019' }
    for i, fg in ipairs(quotes) do
      set('RenderMarkdownQuote' .. i, { fg = fg })
    end

    -- Callout labels
    set('RenderMarkdownInfo',    { fg = '#83a598', bold = true })
    set('RenderMarkdownSuccess', { fg = '#b8bb26', bold = true })
    set('RenderMarkdownHint',    { fg = '#8ec07c', bold = true })
    set('RenderMarkdownWarn',    { fg = '#fabd2f', bold = true })
    set('RenderMarkdownError',   { fg = '#fb4934', bold = true })
  end

  markdown_colors()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group    = vim.api.nvim_create_augroup('MarkdownColors', {}),
    callback = markdown_colors,
    desc     = 'Re-apply markdown render highlights',
  })

  add({ source = 'MeanderingProgrammer/render-markdown.nvim' })

  require('render-markdown').setup({
    file_types = { 'markdown', 'markdown.mdx' },
    -- Sign column already carries diff + diagnostics; keep it uncluttered
    sign  = { enabled = false },
    -- No utftex / latex2text on this machine
    latex = { enabled = false },
    -- These need the html / yaml tree-sitter parsers, which Neovim doesn't
    -- bundle; the regex syntax already colours yaml frontmatter
    html  = { enabled = false },
    yaml  = { enabled = false },

    heading = {
      position = 'inline',  -- conceal the '#'s, put the icon where they were
      width    = 'block',   -- tinted bar hugs the heading text
      right_pad = 3,
      icons    = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
    },

    code = {
      style        = 'full',
      width        = 'block',
      min_width    = 40,
      left_pad     = 2,
      right_pad    = 2,
      border       = 'thick',  -- fence lines become solid bars in the code colour
      language_pad = 1,
      inline_pad   = 1,        -- breathing room around `inline code`
    },

    bullet = {
      icons     = { '●', '○', '◆', '◇' },
      right_pad = 1,
    },

    checkbox = {
      -- stylua: ignore
      custom = {
        todo      = { raw = '[-]', rendered = '󰥔 ', highlight = 'RenderMarkdownTodo' },
        important = { raw = '[!]', rendered = '󰀪 ', highlight = 'RenderMarkdownWarn' },
        cancelled = { raw = '[~]', rendered = '󰅖 ', highlight = 'RenderMarkdownError' },
        question  = { raw = '[?]', rendered = '󰘥 ', highlight = 'RenderMarkdownInfo' },
      },
    },

    quote = {
      icon             = '▋',
      repeat_linebreak = true,  -- needs the showbreak/breakindent set below
    },

    pipe_table = {
      preset              = 'round',
      alignment_indicator = '━',
    },

    -- Completion for callout names ([!NOTE], …) and checkbox states through the
    -- plugin's in-process LSP, which mini.completion already talks to
    completions = { lsp = { enabled = true } },
  })

  -- ── Prose-friendly buffer setup ────────────────────────────────────────────
  -- Called with the buffer current (and its window current, for the display
  -- options below).
  local function markdown_buf_setup(buf)
    -- Neovim 0.12's markdown ftplugin starts the treesitter highlighter, but the
    -- only bundled parsers are markdown/lua/vim/c/query/vimdoc — every other
    -- fenced language then renders as one flat colour, because the markdown
    -- query paints the whole block with @markup.raw.block (priority 90) and that
    -- sits above the syntax layer. The bundled regex syntax files cover ~30
    -- languages, so prefer those. render-markdown parses the tree itself and is
    -- unaffected; only `:checkhealth render-markdown` notices (it wants the
    -- treesitter highlighter enabled). Swap this out if nvim-treesitter and its
    -- parsers ever get added.
    if vim.b[buf].ts_highlight then
      vim.treesitter.stop(buf)
      vim.bo[buf].syntax = vim.bo[buf].filetype  -- FileType skipped this while ts was on
    end

    local o = vim.opt_local
    o.wrap           = true   -- global default is nowrap
    o.linebreak      = true   -- break at word boundaries
    o.breakindent    = true
    o.breakindentopt = ''     -- required by quote.repeat_linebreak
    o.showbreak      = '  '   -- ditto
    o.list           = false

    -- Indent guides add noise to a rendered document
    vim.b[buf].miniindentscope_disable = true

    -- Move by screen line over wrapped prose, but keep counts literal (3j)
    for _, mode in ipairs({ 'n', 'x' }) do
      vim.keymap.set(mode, 'j', "v:count == 0 ? 'gj' : 'j'", { buffer = buf, expr = true, desc = 'Down (screen line)' })
      vim.keymap.set(mode, 'k', "v:count == 0 ? 'gk' : 'k'", { buffer = buf, expr = true, desc = 'Up (screen line)' })
    end

    -- Cycle the checkbox on the current line: none → [ ] → [x] → [ ]
    vim.keymap.set('n', '<leader>mx', function()
      local line = vim.api.nvim_get_current_line()
      local new
      if line:match('^%s*[-*+]%s+%[ %]') then
        new = line:gsub('%[ %]', '[x]', 1)
      elseif line:match('^%s*[-*+]%s+%[[^%]]%]') then
        new = line:gsub('%[[^%]]%]', '[ ]', 1)
      elseif line:match('^%s*[-*+]%s+') then
        new = line:gsub('^(%s*[-*+]%s+)', '%1[ ] ', 1)
      else
        new = line:gsub('^(%s*)', '%1- [ ] ', 1)
      end
      vim.api.nvim_set_current_line(new)
    end, { buffer = buf, desc = 'Toggle checkbox' })

    -- Jump to a heading (ATX only, skipping fenced code blocks)
    vim.keymap.set('n', '<leader>mh', function()
      local items, in_fence = {}, false
      for lnum, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        if line:match('^%s*```') or line:match('^%s*~~~') then
          in_fence = not in_fence
        elseif not in_fence then
          local hashes, title = line:match('^(#+)%s+(.+)$')
          if hashes then
            table.insert(items, {
              text  = ('%s%s'):format(('  '):rep(#hashes - 1), title),
              bufnr = buf,
              lnum  = lnum,
            })
          end
        end
      end
      if #items == 0 then return vim.notify('No headings found', vim.log.levels.INFO) end
      MiniPick.start({ source = { items = items, name = 'Headings' } })
    end, { buffer = buf, desc = 'Pick heading' })
  end

  vim.api.nvim_create_autocmd('FileType', {
    pattern  = { 'markdown', 'markdown.mdx' },
    desc     = 'Markdown buffer options and maps',
    callback = function(ev) markdown_buf_setup(ev.buf) end,
  })

  -- This runs from `later()`, so a markdown file passed on the command line (or
  -- restored from a session) already fired FileType. Catch those up.
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype:match('^markdown') then
      vim.api.nvim_win_call(win, function() markdown_buf_setup(buf) end)
    end
  end

  vim.keymap.set('n', '<leader>mt', '<Cmd>RenderMarkdown toggle<CR>', { desc = 'Toggle markdown render' })
end)
