local M = {}
local config = require("scratch.config")
local utils = require("scratch.utils")

local function write_lines_to_buffer(lines)
	local bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

local function hasDefaultContent(ft)
	local config_data = config.getConfig()
	return config_data.filetype_details[ft]
		and config_data.filetype_details[ft].content
		and #config_data.filetype_details[ft].content > 0
end

local function hasCursorPosition(ft)
	local config_data = config.getConfig()
	return config_data.filetype_details[ft]
		and config_data.filetype_details[ft].cursor
		and #config_data.filetype_details[ft].cursor.location > 0
end

---@param filename string
function M.createScratchFileByName(filename)
	local config_data = config.getConfig()
	local scratch_file_dir = config_data.scratch_file_dir
	utils.initDir(scratch_file_dir)

	local fullpath = scratch_file_dir .. "/" .. filename
	vim.cmd(":e " .. fullpath)
end

local function registerLocalKey()
	local localKeys = config.getLocalKeys()
	if localKeys and #localKeys > 0 then
		for _, key in ipairs(localKeys) do
			for _, namePattern in ipairs(key.filenameContains) do
				if utils.filenameContains(namePattern) then
					utils.setLocalKeybindings(key.LocalKeys)
				end
			end
		end
	end
end

---@param ft string
function M.createScratchFileByType(ft)
	local config_data = config.getConfig()
	local parentDir = config_data.scratch_file_dir
	utils.initDir(parentDir)

	local subdir = config.getConfigSubDir(ft)
	if subdir ~= nil then
		parentDir = parentDir .. "/" .. subdir
		utils.initDir(parentDir)
	end

	local fullpath = utils.genFilepath(ft, config.getConfigFilename(ft), parentDir, config.getConfigRequiresDir(ft))
	vim.cmd(":e " .. fullpath)

	registerLocalKey()

	if hasDefaultContent(ft) then
		write_lines_to_buffer(config_data.filetype_details[ft].content)
	end

	if hasCursorPosition(ft) then
		vim.api.nvim_win_set_cursor(0, config_data.filetype_details[ft].cursor.location)
		if config_data.filetype_details[ft].cursor.insert_mode then
			vim.api.nvim_feedkeys("a", "n", true)
		end
	end
end

local function getFiletypes()
	local config_data = config.getConfig()
	local combined_filetypes = {}
	for _, ft in ipairs(config_data.filetypes) do
		if not vim.tbl_contains(combined_filetypes, ft) then
			table.insert(combined_filetypes, ft)
		end
	end

	for ft, _ in pairs(config_data.filetype_details) do
		if not vim.tbl_contains(combined_filetypes, ft) then
			table.insert(combined_filetypes, ft)
		end
	end
	return combined_filetypes
end

local function selectFiletypeAndDo(func)
	local filetypes = getFiletypes()

	vim.ui.select(filetypes, {
		prompt = "Select filetype",
		format_item = function(item)
			return item
		end,
	}, function(choosedFt)
		if choosedFt then
			func(choosedFt)
		end
	end)
end

local function getScratchFiles()
	local config_data = config.getConfig()
	local scratch_file_dir = config_data.scratch_file_dir
	local res = {}
	res = utils.listDirectoryRecursive(scratch_file_dir)
	for i, str in ipairs(res) do
		res[i] = string.sub(str, string.len(scratch_file_dir) + 2)
	end
	return res
end

function M.scratch()
	selectFiletypeAndDo(M.createScratchFileByType)
end

function M.scratchWithName()
	vim.ui.input({
		prompt = "Enter the file name: ",
	}, function(filename)
		M.createScratchFileByName(filename)
	end)
end

function M.openScratch()
	local files = getScratchFiles()
	local config_data = config.getConfig()
	local scratch_file_dir = config_data.scratch_file_dir

	-- sort the files by their last modified time in descending order
	table.sort(files, function(a, b)
		return vim.fn.getftime(scratch_file_dir .. "/" .. a) > vim.fn.getftime(scratch_file_dir .. "/" .. b)
	end)

	vim.ui.select(files, {
		prompt = "Select old scratch files",
		format_item = function(item)
			return item
		end,
	}, function(chosenFile)
		if chosenFile then
			vim.cmd(":e " .. scratch_file_dir .. "/" .. chosenFile)
			registerLocalKey()
		end
	end)
end

function M.fzfScratch()
	local config_data = config.getConfig()
	local scratch_file_dir = config_data.scratch_file_dir
	require("telescope.builtin").live_grep({
		cwd = scratch_file_dir,
	})
end

return M