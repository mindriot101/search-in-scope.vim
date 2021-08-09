-- defines which file types use which mappings
local FILETYPE_MAP = {
    indent = {"python", "yaml", "cloudformation"},
    braces = {"c", "php", "rust", "cpp", "go"},
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
    if vim.tbl_contains(FILETYPE_MAP.braces, vim.bo.filetype) then
        vim.cmd([[
            execute "normal! vi{\<esc>"
        ]])
    elseif vim.tbl_contains(FILETYPE_MAP.indent, vim.bo.filetype) then
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

function select_indent_region_old()
    local start = v.getpos(".")
    local l0 = v.line(".")
    local l1 = v.line(".")
    local c0 = v.col(".")
    local c1 = v.col(".")

    local itr_count = 0
    local cnt = 1
    local idnt_invalid = 1000

    while cnt > 0 do
        -- loop ieration
        local l = l0
        local idnt = idnt_invalid
        while l <= l1 do
            if not on_empty_line(l) then
                idnt = v.min({idnt, v.indent(l)})
            end
            l = l + 1
        end

        -- keep track of where the range should be expanded to
        local l_1 = l0
        local l_1o = l_1
        local l2 = l1
        local l2o = l2

        if idnt == idnt_invalid then
            local idnt = 0
            local pnb = v.prevnonblank(l0)
            if pnb then
                idnt = v.max({idnt, v.indent(pnb)})
                l_1 = pnb
            end
            local nnb = v.nextnonblank(l0)
            if nnb then
                idnt = v.max({idnt, v.indent(nnb)})
            end

            if idnt > v.indent(pnb) then
                l_1 = nnb
            end
            if idnt > v.indent(nnb) then
                l2 = pnb
            end
        end

        local blnk = on_empty_line(l_1)
        while l_1 > 0 and (blnk or v.indent(l_1) >= idnt) do
            if idnt == 0 and blnk then
                break
            end
            if not blnk then
                l_1o = l_1
            end
            l_1 = l_1 - 1
            blnk = on_empty_line(l_1)
        end

        local line_cnt = v.line("$")
        blnk = on_empty_line(l2)
        while l2 <= line_cnt and (blnk or v.indent(l2) >= idnt) do
            if idnt == 0 and blnk then
                break
            end
            if not blnk then
                l2o = l2
            end
            l2 = l2 + 1
            blnk = on_empty_line(l2)
        end

        local idnt2 = v.max({v.indent(l_1), v.indent(l2)})
        l_1 = l_1o
        l2 = l2o
        l_1 = v.max({l_1, 1})
        l2 = v.min({l2, v.line("$")})

        local c_1 = v.match(v.getline(l_1), "\\c\\S") + 1
        local c2 = v.len(v.getline(l2))

        if itr_count == 0 and l0 == l_1 and l1 == l2 then
            c_1 = c0
            c2 = c1
        end

        local chg = 0
        chg = chg or l0 ~= l_1
        chg = chg or l1 ~= l2
        chg = chg or c0 ~= c_1
        chg = chg or c1 ~= c2

        l0 = l_1
        l1 = l2
        c0 = c_1
        c1 = c2

        if chg then
            cnt = cnt - 1
        else
            if l0 == 0 then
                return
            end
            l0 = l0 - 1
            c0 = v.len(v.getline(l0))
        end

        itr_count = itr_count + 1
    end

    v.cursor(l0, c0)
    vim.cmd([[
        execute "normal! V"
    ]])
    v.cursor(l1, c1)
    vim.cmd([[
        normal! o
        execute "normal! \<esc>"
    ]])
    v.setpos(".", start)
end

function M.setup(user_opts)
    if user_opts.bind then
        vim.api.nvim_set_keymap('n', user_opts.bind, [[:call SearchInScope()<Cr>]], { noremap = true, silent = true })
    end

    if user_opts.indent_filetypes then
        FILETYPE_MAP.indent = vim.tbl_extend("force", FILETYPE_MAP.indent, user_opts.indent_filetypes)
    end

    if user_opts.braces_filetypes then
        FILETYPE_MAP.braces = vim.tbl_extend("force", FILETYPE_MAP.braces, user_opts.braces_filetypes)
    end
end

return M
