local sis = require("search_in_scope")

function assert_positions_equal(a, b)
    for i=1, 4 do
        assert.equal(a[i], b[i])
    end
end

describe("selecting a scope", function()
    it("selects a scope between braces", function()
        vim.cmd(":edit tests/files/example.c")
        vim.fn.cursor(3, 1)
        assert.equal(vim.bo.filetype, "c")

        sis.set_visual_range()

        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")

        assert_positions_equal({0, 2, 1, 0}, start_pos)
        assert_positions_equal({0, 4, 9, 0}, end_pos)
    end)
end)
