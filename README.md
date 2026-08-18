# nvim-config

A minimal, fast Neovim (≥ 0.12) config built entirely on [mini.nvim](https://github.com/nvim-mini/mini.nvim).

Startup on MBP M5 is ~20-35ms

![screenshot](screenshot.png)

## Dependencies

- [mini.nvim](https://github.com/nvim-mini/mini.nvim) — auto-bootstrapped on first launch
- [gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) — colorscheme
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) — LSP server configuration
- [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) — in-buffer markdown rendering
- [ripgrep](https://github.com/burntsushi/ripgrep) — required for file/grep search
- [mason](https://github.com/mason-org/mason.nvim) — manage LSPs and other tools

## Install

```bash
git clone https://github.com/miccoh1994/nvim-config ~/.config/nvim
```

Open Neovim — `mini.nvim` and all plugins install automatically.

## Keymaps

Leader key is `Space`.

| Key | Action |
|-----|--------|
| `<leader>e` | Toggle file explorer |
| `<leader>sf` | Search files (rg) |
| `<leader>sg` | Live grep (rg) |
| `<leader>p{char}` | Jump to buffer by char |
| `<leader>b{d,D,ci}` | Delete / force-delete / close inactive buffers |
| `<leader>dj / dk` | Next / prev diagnostic |
| `<leader>g{o,s,l,S,b,c}` | Git: overlay, show at cursor, inline blame, hunks, branches, commits |
| `<leader>l{f,s,S}` | LSP: format, document symbols, workspace symbols |
| `gd / gD / gr / gi / gy` | LSP: goto def (picker if many), peek def, references, implementation, type def |
| `K` | Hover docs |
| `<leader>rn` | Rename |
| `<leader>ca` | Code action |
| `jj` | Escape insert mode |
| `<leader>m{t,x,h}` | Markdown: toggle rendering, toggle checkbox, pick heading |

## File explorer

`<leader>e` opens the [mini.files](https://github.com/nvim-mini/mini.nvim/blob/main/readmes/mini-files.md) explorer at the current file (`<leader>E` opens it at the cwd). Navigation is locked to the project root (git root, else cwd) — `h` won't climb above it.

The explorer is an editable buffer; you make changes by editing it and then pressing `=` to apply them to disk:

| Action | How |
|--------|-----|
| Navigate | `l` / `L` go in, `h` / `H` go out |
| **Create** | Type a new line with the name (end with `/` for a directory) |
| **Rename / move** | Edit the entry's text |
| **Delete** | Delete the line (`dd`) |
| **Apply changes** | `=` |
| Full help | `g?` |

## Git

Diff signs, `<leader>go` for the diff overlay and `<leader>gs` to show the commit under the cursor all come from [mini.diff](https://github.com/nvim-mini/mini.nvim/blob/main/readmes/mini-diff.md) and [mini.git](https://github.com/nvim-mini/mini.nvim/blob/main/readmes/mini-git.md).

`<leader>gl` toggles inline blame for the line under the cursor:

```
  return ('hello, %s'):format(name)      Michael Cohen · 3 days ago · fix picker paste
```

It stays off until you ask for it, then follows the cursor (debounced 150 ms, results cached per line) and hides itself in insert mode. Unsaved lines are piped through `git blame --contents -`, so blame stays correct in a modified buffer and new lines read `Uncommitted change`. Untracked files and files outside a repo show nothing.

## Markdown

Markdown files render in-buffer with [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim): heading bars with icons, code blocks as cards with the language and its icon, `●/○/◆/◇` bullets, checkboxes, coloured quote bars, GitHub/Obsidian callouts (`> [!NOTE]`), rounded tables, and link icons per destination. Colours are tuned to gruvbox dark. Raw text comes back on the line the cursor is on, and completely in insert and visual mode.

Markdown buffers also get soft wrap at word boundaries, `j`/`k` by screen line (counts stay literal, so `3j` is 3 real lines), and no indent guides.

| Key | Action |
|-----|--------|
| `<leader>mt` | Toggle rendering (see the raw document) |
| `<leader>mx` | Toggle / insert a checkbox on the current line |
| `<leader>mh` | Fuzzy-pick a heading and jump to it |
| `gO` | Table of contents (built into Neovim) |
| `]]` / `[[` | Next / previous section (built into Neovim) |

Beyond the defaults, `[-]`, `[!]`, `[~]` and `[?]` render as extra checkbox states (in progress, important, cancelled, question), and `==text==` renders as highlighted.

**Code block colours.** Neovim 0.12 starts the tree-sitter highlighter for markdown, but only ships parsers for markdown, lua, vim, c, query and vimdoc — every other fenced language ends up a single flat colour. This config stops that highlighter in markdown buffers and uses Neovim's bundled regex syntax files instead, so `:checkhealth render-markdown` reports `highlighter: not enabled`; rendering itself is unaffected. If you install nvim-treesitter and its parsers, drop the `vim.treesitter.stop` block and the `markdown_fenced_languages` list.

Languages come from `g:markdown_fenced_languages` in `init.lua`. Each entry sources a syntax file the first time a markdown buffer highlights (~35 ms for markdown alone, ~65 ms with the current 22 entries), so add the ones you write and leave out the rest — java costs +30 ms, html +20 ms, vim and rust +15 ms each, css +14 ms.

## LSP

Servers are configured at the bottom of `init.lua`. Uncomment the ones you need and ensure the server binary is on your `$PATH`.
