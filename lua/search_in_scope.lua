local M = {}

function M.set_visual_range()
    vim.cmd([[
        execute "normal! vi{\<esc>"
    ]])
end

return M
