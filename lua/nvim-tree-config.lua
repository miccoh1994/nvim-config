local nvim_tree_config = {}

local function tree_actions_menu(node)
	-- Tree Actions
	--
	local tree_actions = {
		{
			name = "Create Node",
			handler = require("nvim-tree.api").fs.create,
		},
		{
			name = "Remove Node",
			handler = require("nvim-tree.api").fs.remove,
		},
		{
			name = "Trash Node",
			handler = require("nvim-tree.api").fs.trash,
		},
		{
			name = "Rename Node",
			handler = require("nvim-tree.api").fs.rename,
		},
		{
			name = "Fully rename node",
			handler = require("nvim-tree.api").fs.rename_sub,
		},
		{
			name = "Copy",
			handler = require("nvim-tree.api").fs.copy.node,
		},
	}
	local entry_maker = function(menu_item)
		return {
			value = menu_item,
			ordinal = menu_item.name,
			display = menu_item.name,
		}
	end
	local finder = require("telescope.finders").new_table({
		results = tree_actions,
		entry_maker = entry_maker,
	})

	local sorter = require("telescope.sorters").get_generic_fuzzy_sorter()

	local default_options = {
		finder = finder,
		sorter = sorter,
		attach_mappings = function(prompt_buffer_number)
			local actions = require("telescope.actions")

			actions.select_default:replace(function()
				local state = require("telescope.actions.state")
				local selection = state.get_selected_entry()
				-- Close the picker
				actions.close(prompt_buffer_number)
				-- Call the handler
				selection.value.handler(node)
			end)

			-- The following actions are disabled in this example
			-- You may want to map them too depending on your needs though
			actions.add_selection:replace(function() end)
			actions.remove_selection:replace(function() end)
			actions.toggle_selection:replace(function() end)
			actions.select_all:replace(function() end)
			actions.drop_all:replace(function() end)
			actions.toggle_selection:replace(function() end)
			return true
		end,
	}

	-- Opening the menu
	require("telescope.pickers").new({ title = "Tree Menu" }, default_options):find()
end

nvim_tree_config.config = function()
	local api = require("nvim-tree.api")
	-- default mappings
	vim.keymap.set("n", "<leader>ff", api.tree.toggle, { desc = "Toggle File Tree" })
	require("nvim-tree").setup({
		on_attach = function(buffer)
			vim.keymap.set(
				"n",
				"<leader>fn",
				tree_actions_menu,
				{ buffer = buffer, noremap = true, silent = true, desc = "Tree Actions" }
			)
			local keymap = require("nvim-tree.keymap")
			keymap.default_on_attach(buffer)
		end,
		view = {
			width = 60
		}
	})
end

return nvim_tree_config.config
