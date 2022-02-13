local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error "This extension requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)"
end

local actions = require('telescope.actions')
local action_state = require "telescope.actions.state"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"
local putils = require "telescope.previewers.utils"
local utils = require "telescope.utils"


local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local lookup_keys = {
    display = 1,
    ordinal = 1,
    value = 1,
}

local mt_string_entry = {
    __index = function(t, k)
        return rawget(t, rawget(lookup_keys, k))
    end,
}

local get_artisan_command = function()
    if vim.call('composer#query', 'require-dev.laravel/sail') == "" then
        return "php artisan"
    else
        return "sail art"
    end
end

local function getArtisanCommand(args)
    local artisan_cmd = get_artisan_command()

    if type(args) ~= "table" then
        return split(artisan_cmd .. ' ' .. args, " ")
    end
    local cmd = split(artisan_cmd, ' ')
    for _, value in ipairs(args) do
        table.insert(cmd, value)
    end

    return cmd
end

local laravel = function(opts)
    opts = opts or {}

    local results = utils.get_os_command_output(getArtisanCommand('--raw'))

    pickers.new({}, {
        prompt_title = "Artisan commands",
        finder = finders.new_table {
            results = results,
            entry_maker = function (line)
                return setmetatable({
                    split(line, " ")[1],
                }, mt_string_entry)
            end
        },
        previewer = previewers.new_buffer_previewer {
            title = "Help",
            get_buffer_by_name = function(_, entry)
                return entry.value
            end,

            define_preview = function(self, entry)

                local cmd = getArtisanCommand({entry.value, '-h'})

                putils.job_maker(cmd, self.state.bufnr, {
                    value = entry.value,
                    bufname = self.state.bufname,
                })
            end,
        },
        sorter = conf.file_sorter(),
        attach_mappings = function (_, map)
            map('i', '<cr>', function(prompt_bufnr)
                local entry = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                local cmd = string.format(":!%s %s ", get_artisan_command(), entry.value)
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd, true, false, true), "t", true)
            end)
            return true
        end
    }):find()
end


return telescope.register_extension {
  exports = {
    laravel = laravel,
  },
}
