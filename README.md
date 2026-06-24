# nvim-config

A minimal, fast Neovim (≥ 0.12) config built entirely on [mini.nvim](https://github.com/nvim-mini/mini.nvim).

Startup on MBP M5 is ~20-35ms

![screenshot](screenshot.png)

## Dependencies

- [mini.nvim](https://github.com/nvim-mini/mini.nvim) — auto-bootstrapped on first launch
- [gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) — colorscheme
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) — LSP server configuration
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
| `<leader>g{o,s,S,b,c}` | Git: overlay, show, hunks, branches, commits |
| `<leader>l{f,s,S}` | LSP: format, document symbols, workspace symbols |
| `gd / gD / gr / gi / gy` | LSP: goto def (picker if many), peek def, references, implementation, type def |
| `K` | Hover docs |
| `<leader>rn` | Rename |
| `<leader>ca` | Code action |
| `jj` | Escape insert mode |

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

## LSP

Servers are configured at the bottom of `init.lua`. Uncomment the ones you need and ensure the server binary is on your `$PATH`.
