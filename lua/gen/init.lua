local M = {}
local curr_buffer = nil
local start_pos = nil
local end_pos = nil
local prompts = require('gen.prompts')
local exec = require('gen.exec')
local exec_docker = require('gen.exec_docker')
local config = require('gen.config')
local utility = require('gen.utility')

M.useDocker = true
M.model = 'llama2'

local function trim_table(tbl)
    local function is_whitespace(str) return str:match("^%s*$") ~= nil end

    while #tbl > 0 and (tbl[1] == "" or is_whitespace(tbl[1])) do
        table.remove(tbl, 1)
    end

    while #tbl > 0 and (tbl[#tbl] == "" or is_whitespace(tbl[#tbl])) do
        table.remove(tbl, #tbl)
    end

    return tbl
end

local function get_window_options()

    local width = math.floor(vim.o.columns * 0.9) -- 90% of the current editor's width
    local height = math.floor(vim.o.lines * 0.9)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local cursor = vim.api.nvim_win_get_cursor(0)
    local new_win_width = vim.api.nvim_win_get_width(0)
    local win_height = vim.api.nvim_win_get_height(0)

    local middle_row = win_height / 2

    local new_win_height = math.floor(win_height / 2)
    local new_win_row
    if cursor[1] <= middle_row then
        new_win_row = 5
    else
        new_win_row = -5 - new_win_height
    end

    return {
        relative = 'cursor',
        width = new_win_width,
        height = new_win_height,
        row = new_win_row,
        col = 0,
        style = 'minimal',
        border = 'single'
    }
end

if M.useDocker then
    M.command = 'docker exec ollama ollama run $model $prompt'
    M.exec_docker = exec_docker(options)
    M.prompts = prompts
    config(cb)
    print("Using Docker...")
else
    M.command = 'ollama run $model $prompt'
    M.exec = exec(options)
    M.prompts = prompts
    config(cb)
    print("AAAAAAAAAAAAAAAAAAAAAAAAAAAA")
end

vim.api.nvim_create_user_command('Gen', function(arg)
    local mode
    if arg.range == 0 then
        mode = 'n'
    else
        mode = 'v'
    end
    if arg.args ~= '' then
        local prompt = M.prompts[arg.args]
        if not prompt then
            print("Invalid prompt '" .. arg.args .. "'")
            return
        end
        p = vim.tbl_deep_extend('force', {mode = mode}, prompt)
        return M.exec(p)
    end
    select_prompt(function(item)
        if not item then return end
        p = vim.tbl_deep_extend('force', {mode = mode}, M.prompts[item])
        M.exec(p)
    end)

end, {
  range = true,
  nargs = '?',
  complete = function(ArgLead, CmdLine, CursorPos)
    local promptKeys = {}
    for key, _ in pairs(M.prompts) do
      if key:lower():match("^"..ArgLead:lower()) then
        table.insert(promptKeys, key)
      end
    end
    table.sort(promptKeys)
    return promptKeys
  end
})

return M
