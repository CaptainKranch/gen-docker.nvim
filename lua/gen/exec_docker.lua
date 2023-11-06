local function exec_docker(options)
    local opts = vim.tbl_deep_extend('force', {
        model = M.model,
        command = M.command
    }, options)
    --pcall(io.popen, 'ollama serve > /dev/null 2>&1 &')
    curr_buffer = vim.fn.bufnr('%')
    local mode = opts.mode or vim.fn.mode()
    if mode == 'v' or mode == 'V' then
        start_pos = vim.fn.getpos("'<")
        end_pos = vim.fn.getpos("'>")
        end_pos[3] = vim.fn.col("'>") -- in case of `V`, it would be maxcol instead
    else
        local cursor = vim.fn.getpos('.')
        start_pos = cursor
        end_pos = start_pos
    end

    local content = table.concat(vim.api.nvim_buf_get_text(curr_buffer,
                                                           start_pos[2] - 1,
                                                           start_pos[3] - 1,
                                                           end_pos[2] - 1,
                                                           end_pos[3] - 1, {}),
                                 '\n')

    local function substitute_placeholders(input)
        if not input then return end
        local text = input
        if string.find(text, "%$input") then
            local answer = vim.fn.input("Prompt: ")
            text = string.gsub(text, "%$input", answer)
        end

        if string.find(text, "%$register") then
          local register = vim.fn.getreg('"')
          if not register or register:match("^%s*$") then
            error("Prompt uses $register but yank register is empty")
          end

          text = string.gsub(text, "%$register", register)
        end

        text = string.gsub(text, "%$text", content)
        text = string.gsub(text, "%$filetype", vim.bo.filetype)
        return text
    end

    local prompt = opts.prompt

    if type(prompt) == "function" then
      prompt = prompt({
        content = content,
        filetype = vim.bo.filetype,
      })
    end

    prompt = vim.fn.shellescape(substitute_placeholders(prompt))
    local extractor = substitute_placeholders(opts.extract)
    local cmd = opts.command
    cmd = string.gsub(cmd, "%$prompt", prompt)
    cmd = string.gsub(cmd, "%$model", opts.model)
    if result_buffer then vim.cmd('bd' .. result_buffer) end
    local win_opts = get_window_options()
    result_buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(result_buffer, 'filetype', 'markdown')

    local float_win = vim.api.nvim_open_win(result_buffer, true, win_opts)

    local result_string = ''
    local lines = {}
    local job_id
    job_id = vim.fn.jobstart(cmd, {
        on_stdout = function(_, data, _)
            -- window was closed, so cancel the job
            if not vim.api.nvim_win_is_valid(float_win) then
              vim.fn.jobstop(job_id)
              return
            end
            result_string = result_string .. table.concat(data, '\n')
            lines = vim.split(result_string, '\n', true)
            vim.api.nvim_buf_set_lines(result_buffer, 0, -1, false, lines)
            vim.api.nvim_win_call(float_win, function()
              vim.fn.feedkeys('$')
            end)
        end,
        on_exit = function(a, b)
            if b == 0 and opts.replace then
                if extractor then
                    local extracted = result_string:match(extractor)
                    if not extracted then
                        vim.cmd('bd ' .. result_buffer)
                        return
                    end
                    lines = vim.split(extracted, '\n', true)
                end
                lines = trim_table(lines)
                vim.api.nvim_buf_set_text(curr_buffer, start_pos[2] - 1,
                                          start_pos[3] - 1, end_pos[2] - 1,
                                          end_pos[3] - 1, lines)
                vim.cmd('bd ' .. result_buffer)
            end
        end
    })
    vim.keymap.set('n', '<esc>', function() vim.fn.jobstop(job_id) end,
                   {buffer = result_buffer})

    vim.api.nvim_buf_attach(result_buffer, false,
                            {on_detach = function() result_buffer = nil end})

end
