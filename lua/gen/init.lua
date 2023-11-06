local M = {}
local curr_buffer = nil
local start_pos = nil
local end_pos = nil
local prompts = require('gen.prompts')
local exec = requiere('gen.exec')
local exec_docker = requiere('gen.exec_docker')
local config = requiere('gen.config')

M.useDocker = false
M.model = 'llama2'

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
