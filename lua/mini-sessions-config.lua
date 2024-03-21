local MiniSessionConfig = {}
MiniSessionConfig.setup = function()
	vim.opt.sessionoptions:append("globals")

	-- use .idea directory for sessions if in a git repo, so don't need to add to .gitignore
	local sessiondir = vim.fn.getcwd() .. "/.idea/nvim-sessions"
	local gitRoot = vim.fn.finddir(".git", ".;")
	local auto_read = true
	local auto_write = true
	if gitRoot ~= "" then
		local without_git_in_path = vim.fn.fnamemodify(gitRoot, ":p:h:h")
		sessiondir = without_git_in_path .. "/.idea" .. "/nvim-sessions"
		-- make a session directory if it doesn't exist
		vim.fn.mkdir(sessiondir, "p")
	else -- If we are not in a git repo, we disable auto read and write and global session options
		sessiondir = ''
		auto_read = false
		auto_write = false
	end



	local sessions = require("mini.sessions")
	sessions.setup({
		auto_read = auto_read,
		auto_write = auto_write,
		directory = sessiondir,
		hook = {
			pre = {
				write = function()
					vim.api.nvim_exec_autocmds('User', { 'SessionSavePre' })
				end
			}
		}
	})
	if gitRoot ~= "" then
		local n_sessions = vim.tbl_count(sessions.detected)
		local without_git_in_path = vim.fn.fnamemodify(gitRoot, ":p:h:h")
		local root_name = vim.fn.fnamemodify(without_git_in_path, ":t:t")
		if n_sessions > 0 then
			-- try open the last session
			if n_sessions > 1 then
				sessions.select()
			else
				sessions.read(root_name)
			end
		else
			-- create a new session
			sessions.write(root_name)
		end
	end
	-- get the open buffers
	-- local open_buffers = vim.fn.getbufinfo({ buflisted = 1 })
	-- for _, buffer in ipairs(open_buffers) do
	--   -- if the buffer name includes "NvimTree"
	--   if string.find(buffer.name, "NvimTree") then
	--     -- open the sidebar buffer
	--     require("nvim-tree.api").tree.toggle({
	--       focus = false
	--     })
	--   end
	-- end
	--  Check out: https://github.com/echasnovski/mini.nvim
end

return MiniSessionConfig
