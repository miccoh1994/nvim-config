local nvim_tree_config = {}



local function edit_or_open()
	local api = require("nvim-tree.api")
	local node = api.tree.get_node_under_cursor()

	if node.nodes ~= nil then
		-- expand or collapse folder
		api.node.open.edit()
	else
		-- open file
		api.node.open.edit()
		-- Close the tree if file was opened
		api.tree.close()
	end
end

-- open as vsplit on current node
local function vsplit_preview()
	local api = require("nvim-tree.api")
	local node = api.tree.get_node_under_cursor()

	if node.nodes ~= nil then
		-- expand or collapse folder
		api.node.open.edit()
	else
		-- open file as vsplit
		api.node.open.vertical()
	end

	-- Finally refocus on tree if it was lost
	api.tree.focus()
end

nvim_tree_config.config = function()
	-- default mappings
	local api = require("nvim-tree.api")
	vim.keymap.set("n", "<leader>ff", api.tree.toggle, { desc = "Toggle File Tree" })
	require("nvim-tree").setup({
		on_attach = function(buffer)
			local opts = function(desc)
				return { buffer = buffer, desc = desc, silent = true, noremap = true }
			end
			vim.keymap.set("n", "l", edit_or_open, opts("Edit Or Open"))
			vim.keymap.set("n", "L", vsplit_preview, opts("Vsplit Preview"))
			vim.keymap.set("n", "h", api.tree.close, opts("Close"))
			vim.keymap.set("n", "H", api.tree.collapse_all, opts("Collapse All"))
			vim.keymap.set("n", "n", api.fs.create, opts("Create Node"))
			vim.keymap.set("n", "r", api.fs.rename, opts("Rename Node"))
			local keymap = require("nvim-tree.keymap")
			keymap.default_on_attach(buffer)
		end,
		view = {
			width = {
				min = 60,
				padding = 0
			}
		},
		renderer = {
			root_folder_label = false,
			highlight_git = "icon",
			highlight_diagnostics = "icon",
			icons = {
				git_placement = "after",
			}
		},
		filters = {
			custom = { ".git"},
			dotfiles = false,
			exclude = { ".gitignore" }
		}
	})
end

local function open_nvim_tree(data)
	-- buffer is a real file on the disk
	local real_file = vim.fn.filereadable(data.file) == 1

	-- buffer is a [No Name]
	local no_name = data.file == '' and vim.bo[data.buf].buftype == ''

	-- only files please
	if not real_file and not no_name then
		return
	end

	-- open the tree but dont focus it
	require('nvim-tree.api').tree.toggle({ focus = false })
	vim.api.nvim_exec_autocmds('BufWinEnter', { buffer = require('nvim-tree.view').get_bufnr() })
end

vim.api.nvim_create_autocmd({ 'VimEnter' }, { callback = open_nvim_tree })
vim.api.nvim_create_autocmd({ 'VimLeavePre' }, { callback = function()
	require('nvim-tree.api').tree.close()
end })


return nvim_tree_config.config
