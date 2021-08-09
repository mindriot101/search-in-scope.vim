function Set(list)
    local set = {}
    for _, l in ipairs(list) do
        set[l] = true
    end
    return set
end

-- defines which file types use which mappings
local FILETYPE_MAP = {
    indent = Set{"python", "yaml", "cloudformation"},
    braces = Set{"c", "php", "rust", "cpp", "go"},
}

local M = {}

M.config = {
}

function M.search_in_scope()
    local pos = vim.fn.getpos(".")
    M.set_visual_range()
    print(vim.inspect(vim.fn.getpos("'<")))
    print(vim.inspect(vim.fn.getpos("'>")))
    vim.fn.setpos(".", pos)
    vim.fn.feedkeys([[/\%V]], 'n')
end

function M.set_visual_range()
    if FILETYPE_MAP.braces[vim.bo.filetype] then
        vim.cmd([[
            execute "normal! vi{\<esc>"
        ]])
    elseif FILETYPE_MAP.indent[vim.bo.filetype] then
        select_indent_region()
    else
        error("unimplemented")
    end
end

function M.find_start_pos(initial)
    vim.validate({
        initial={initial, 'table'}
    })
    assert(#initial == 4)
    local line_number = initial[2]
    local indent = vim.fn.indent(line_number)
    assert(indent > 0)

    while line_number >= 1 do
        local curr_indent = vim.fn.indent(line_number)
        if curr_indent < indent then
            return {initial[1], line_number + 1, 1, 0}
        end
        line_number = line_number - 1
    end
    -- could not find the start pos
    return nil
end

function M.find_end_pos(initial)
    vim.validate({
        initial={initial, 'table'}
    })
    assert(#initial == 4)
    local line_number = initial[2]
    local indent = vim.fn.indent(line_number)
    assert(indent > 0)

    local num_lines = vim.fn.line("$")

    while line_number <= num_lines do
        local curr_indent = vim.fn.indent(line_number)
        if curr_indent < indent then
            local return_line_number = line_number - 1
            -- temporarily set the cursor to find the end of the line
            vim.fn.cursor(return_line_number, 1)
            vim.cmd([[
                normal $
            ]])
            local pos = vim.fn.getcurpos()
            local return_col_number = pos[3] + 1
            return {initial[1], return_line_number, return_col_number, 0}
        end
        line_number = line_number + 1
    end

    -- assume end of file
    return {initial[1], vim.fn.line("$"), 1, 0}
end

function on_empty_line(l)
    return string.match(v.getline(l), "%s*$")
end

function no_indent(pos)
    -- TODO: validate that argument is a length-4 list of [bufnum, lnum, col, off]
    vim.validate({
        pos={pos, 'table'},
    })
    return vim.fn.indent(pos[2]) == 0
end

function visual_select_file(pos)
    vim.cmd([[
        execute "normal! ggVG\<esc>"
    ]])
end

function select_indent_region()
    local initial = vim.fn.getpos(".")
    -- special case: if there is no indent then select the whole scope
    if no_indent(initial) then
        visual_select_file(initial)
    end
    local start_pos = M.find_start_pos(initial)
    local end_pos = M.find_end_pos(initial)
    select_region(initial, start_pos, end_pos)
end

function select_region(initial, start_pos, end_pos)
    vim.fn.cursor(start_pos[2], start_pos[3])
    vim.cmd([[
        execute "normal! V"
    ]])
    vim.fn.cursor(end_pos[2], end_pos[3])
    vim.cmd([[
        execute "normal! \<esc>"
    ]])
    vim.fn.setpos(".", initial)
end

function M.setup(user_opts)
    if user_opts.bind then
        vim.api.nvim_set_keymap('n', user_opts.bind, [[:lua require('search_in_scope').search_in_scope()<Cr>]], { noremap = true, silent = true })
    end

    if user_opts.indent_filetypes then
        for _, v in ipairs(user_opts.indent_filetypes) do
            FILETYPE_MAP.indent[v] = true
        end
    end

    if user_opts.braces_filetypes then
        for _, v in ipairs(user_opts.braces_filetypes) do
            FILETYPE_MAP.braces[v] = true
        end
    end
end

return M
