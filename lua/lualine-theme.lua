local palette = require('rose-pine.palette')

local colors = {
	bg       = palette.base,
	fg       = palette.love,
	yellow   = palette.gold,
	cyan     = palette.foam,
	darkblue = palette.overlay,
	violet   = palette.rose,
	magenta  = palette.iris,
	blue     = palette.pine,
	red      = '#ec5f67',
	orange   = '#FF8800',
	green    = '#98be65',
}

local conditions = {
	buffer_not_empty = function()
		return vim.fn.empty(vim.fn.expand('%:t')) ~= 1
	end,
	hide_in_width = function()
		return vim.fn.winwidth(0) > 80
	end,
	check_git_workspace = function()
		local filepath = vim.fn.expand('%:p:h')
		local gitdir = vim.fn.finddir('.git', filepath .. ';')
		return gitdir and #gitdir > 0 and #gitdir < #filepath
	end,
}

-- Config
local config = {
	options = {
		-- Disable sections and component separators
		component_separators = '',
		section_separators = '',
		theme = 'rose-pine',
		disabled_filetypes = {
			'NvimTree',
		},
	},
	sections = {
		-- these are to remove the defaults
		lualine_a = {},
		lualine_b = {},
		lualine_y = {},
		lualine_z = {},
		-- These will be filled later
		lualine_c = {},
		lualine_x = {},
	}
}

-- Inserts a component in lualine_c at left section
local function ins_left(component)
	table.insert(config.sections.lualine_c, component)
end

-- Inserts a component in lualine_x at right section
local function ins_right(component)
	table.insert(config.sections.lualine_x, component)
end

ins_left {
	function()
		return '▊'
	end,
	color = { fg = colors.blue }, -- Sets highlighting of component
	padding = { left = 0, right = 1 }, -- We don't need space before this
}

ins_left {
	-- mode component
	function()
		return ''
	end,
	color = function()
		-- auto change color according to neovims mode
		local mode_color = {
			n = colors.cyan,
			i = colors.fg,
			v = colors.blue,
			[''] = colors.blue,
			V = colors.blue,
			c = colors.magenta,
			no = colors.red,
			s = colors.orange,
			S = colors.orange,
			[''] = colors.orange,
			ic = colors.yellow,
			R = colors.violet,
			Rv = colors.violet,
			cv = colors.red,
			ce = colors.red,
			r = colors.cyan,
			rm = colors.cyan,
			['r?'] = colors.cyan,
			['!'] = colors.red,
			t = colors.red,
		}
		return { fg = mode_color[vim.fn.mode()] }
	end,
	padding = { right = 1 },
}
--
-- ins_left {
-- 	-- filesize component
-- 	'filesize',
-- 	cond = conditions.buffer_not_empty,
-- }

ins_left {
	'filename',
	cond = conditions.buffer_not_empty,
	color = { fg = colors.magenta },
}

ins_left { 'location' }

ins_left { 'progress', color = { fg = colors.cyan } }

ins_left {
	'diagnostics',
	sources = { 'nvim_diagnostic' },
	symbols = { error = ' ', warn = ' ', info = ' ' },
	diagnostics_color = {
		color_error = { fg = colors.red },
		color_warn = { fg = colors.yellow },
		color_info = { fg = colors.cyan },
	},
}

-- Insert mid section. You can make any number of sections in neovim :)
-- for lualine it's any number greater then 2
ins_left {
	function()
		return '%='
	end,
}

ins_right {
	-- Lsp server name .
	function()
		local msg = 'No Active Lsp'
		local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
		local file_name = vim.fn.expand('%:t')
		local file_extension = vim.fn.expand('%:e')
		local clients = vim.lsp.get_active_clients()
		if next(clients) == nil then
			return msg
		end
		for _, client in ipairs(clients) do
			local filetypes = client.config.filetypes
			if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
				local icon = require('nvim-web-devicons').get_icon(file_name, file_extension)
				return icon
			end
		end
		return msg
	end,
	icon = '',
	color = { fg = colors.blue, },
}

-- Add components to right sections
ins_right {
	'o:encoding', -- option component same as &encoding in viml
	fmt = string.upper, -- I'm not sure why it's upper case either ;)
	cond = conditions.hide_in_width,
	color = { fg = colors.green },
}

-- ins_right {
-- 	'fileformat',
-- 	fmt = string.upper,
-- 	icons_enabled = true, -- I think icons are cool but Eviline doesn't have them. sigh
-- 	color = { fg = colors.green, gui = 'bold' },
-- }

ins_right {
	'branch',
	icon = '',
	color = { fg = colors.violet },
}

ins_right {
	'diff',
	-- Is it me or the symbol for modified us really weird
	symbols = { added = ' ', modified = '󰝤 ', removed = ' ' },
	diff_color = {
		added = { fg = colors.green },
		modified = { fg = colors.orange },
		removed = { fg = colors.red },
	},
	cond = conditions.hide_in_width,
}

return {
	setup = function()
		require('lualine').setup(config)
	end
}
