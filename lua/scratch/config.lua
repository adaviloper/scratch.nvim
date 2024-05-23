local slash = require("scratch.utils").Slash()

---@alias mode
---| '"n"'
---| '"i"'
---| '"v"'

---@class Scratch.LocalKey
---@field cmd string
---@field key string
---@field modes mode[]

---@class Scratch.LocalKeyConfig
---@field filenameContains string[] as long as the filename contains any one of the string in the list
---@field LocalKeys Scratch.LocalKey[]
--
---@class Scratch.Cursor
---@field location number[]
---@field insert_mode boolean

---@class Scratch.FiletypeDetail
---@field filename? string
---@field requireDir? boolean -- TODO: conbine requireDir and subdir into one table
---@field subdir? string
---@field content? string[]
---@field cursor? Scratch.Cursor
--
---@class Scratch.FiletypeDetails
---@field [string] Scratch.FiletypeDetail

---@class Scratch.LuaSetupConfig
---@field json_config_path string

---@class Scratch.Config
---@field scratch_file_dir string
---@field filetypes string[]
---@field window_cmd  string
---@field use_telescope boolean
---@field filetype_details Scratch.FiletypeDetails
---@field localKeys Scratch.LocalKeyConfig[]
local default_config = {
  scratch_file_dir = vim.fn.stdpath("cache") .. slash .. "scratch.nvim",
  filetypes = { "xml", "go", "lua", "js", "py", "sh" }, -- you can simply put filetype here
  window_cmd = "edit", -- 'vsplit' | 'split' | 'edit' | 'tabedit' | 'rightbelow vsplit'
  use_telescope = true,
  filetype_details = { -- or, you can have more control here
    json = {}, -- empty table is fine
    ["yaml"] = {},
    ["k8s.yaml"] = { -- you can have different postfix
      subdir = "learn-k8s", -- and put this in a specific subdir
    },
    go = {
      requireDir = true, -- true if each scratch file requires a new directory
      filename = "main", -- the filename of the scratch file in the new directory
      content = { "package main", "", "func main() {", "  ", "}" },
      cursor = {
        location = { 4, 2 },
        insert_mode = true,
      },
    },
  },
  localKeys = {
    {
      filenameContains = { "gp" },
      LocalKeys = {
        {
          cmd = "<CMD>GpResponse<CR>",
          key = "<C-k>k",
          modes = { "n", "i", "v" },
        },
      },
    },
  },
}

local function editConfig()
  vim.cmd(":e " .. vim.g.scratch_json_config_path)
end

---@return Scratch.Config
local function get_config()
  local json_config = require("scratch.json").read_or_init_json_file(vim.g.scratch_json_config_path)
  vim.g.scratch_config = vim.tbl_deep_extend("force", vim.g.scratch_config, json_config)
    or require("scratch.utils").log_err("Error when tring to get configuration")
  return vim.g.scratch_config
end

vim.g.scratch_config = default_config

---@param user_config? Scratch.LuaSetupConfig
local function setup(user_config)
  vim.g.scratch_json_config_path = user_config and user_config.json_config_path
    or vim.fn.stdpath("config") .. slash .. "scratch_config.json"
end

return {
  setup = setup,
  editConfig = editConfig,
  get_config = get_config,
}
