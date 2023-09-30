local M = {}

local curr_buffer = nil
local start_pos = nil
local end_pos = nil

local function trim_table(tbl)
    local function is_whitespace(str)
        return str:match("^%s*$") ~= nil
    end

    while #tbl > 0 and (tbl[1] == "" or is_whitespace(tbl[1])) do
        table.remove(tbl, 1)
    end

    while #tbl > 0 and (tbl[#tbl] == "" or is_whitespace(tbl[#tbl])) do
        table.remove(tbl, #tbl)
    end

    return tbl
end

M.run_llm = function(prompt)
    curr_buffer = vim.fn.bufnr('%')
    start_pos = vim.fn.getpos("'<")
    end_pos = vim.fn.getpos("'>")
    end_pos[3] = vim.fn.col("'>") -- in case of `V`, it would be maxcol instead

    local lines_table = vim.fn.getline(start_row, end_row)
    local lines = table.concat(lines_table, "\n")
    local content = table.concat(vim.api.nvim_buf_get_text(curr_buffer, start_pos[2] - 1, start_pos[3] - 1, end_pos[2] - 1, end_pos[3] - 1, {}), '\n')
    local text = vim.fn.shellescape(lines)
    local cmd = 'ollama run mistral:instruct """' .. prompt .. '""" """' ..
                    lines .. '"""'
    if result_buffer then vim.cmd('bd' .. result_buffer) end
    vim.cmd('vs enew')
    result_buffer = vim.fn.bufnr('%')
    vim.fn.termopen(cmd .. '\n', {
        on_exit = function()
            local lines = vim.api.nvim_buf_get_lines(result_buffer, 0, -1, false)
            lines = trim_table(lines)
            vim.api.nvim_buf_set_text(curr_buffer, start_pos[2] - 1, start_pos[3] - 1, end_pos[2] - 1, end_pos[3] - 1, lines)
            vim.cmd('bd' .. result_buffer)
            result_buffer = nil
        end
    })
end

vim.api.nvim_create_user_command('Gen', function()
    M.run_llm("Summarize the text")
end, {range = true})

return M