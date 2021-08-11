describe("selecting a scope", function()
    it("selects a scope between braces", function()
        vim.cmd(":view tests/files/example.c")
        vim.fn.cursor(3, 1)
        assert.equal(vim.bo.filetype, "c")

        require("search_in_scope").set_visual_range()

        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")

        assert.are.same({0, 2, 1, 0}, start_pos)
        assert.are.same({0, 4, 9, 0}, end_pos)
    end)

    it("selects a scope with an indent", function()
        vim.cmd(":view tests/files/example.py")
        vim.fn.cursor(5, 9)
        assert.equal(vim.bo.filetype, "python")

        require("search_in_scope").set_visual_range()

        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")

        assert.are.same({0, 3, 1, 0}, start_pos)
        assert.are.same({0, 7, 2^31 - 1, 0}, end_pos)
    end)

    it("selects over new lines", function()
        vim.cmd(":view tests/files/example.py")
        vim.fn.cursor(2, 9)
        assert.equal(vim.bo.filetype, "python")

        require("search_in_scope").set_visual_range()

        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        assert.are.same({0, 2, 1, 0}, start_pos)
        assert.are.same({0, 10, 2^31 - 1, 0}, end_pos)
    end)
end)

describe("helper functions", function()
    it("finds the start position", function()
        vim.cmd(":view tests/files/example.py")
        vim.fn.cursor(5, 9)
        assert.equal(vim.bo.filetype, "python")

        local initial = vim.fn.getpos(".")
        local pos = require("search_in_scope").find_start_pos(initial)

        assert.are.same({0, 3, 1, 0}, pos)
    end)

    it("finds the end position", function()
        vim.cmd(":view tests/files/example.py")
        vim.fn.cursor(5, 9)
        assert.equal(vim.bo.filetype, "python")

        local initial = vim.fn.getpos(".")
        local pos = require("search_in_scope").find_end_pos(initial)

        assert.are.same({0, 7, 14, 0}, pos)
    end)

    it("finds the start position with blank lines", function()
        vim.cmd(":view tests/files/example2.py")
        vim.fn.cursor(7, 9)
        assert.equal(vim.bo.filetype, "python")

        local initial = vim.fn.getpos(".")
        local pos = require("search_in_scope").find_start_pos(initial)

        assert.are.same({0, 3, 1, 0}, pos)
    end)

    it("finds the end position with blank lines", function()
        vim.cmd(":view tests/files/example.py")
        vim.fn.cursor(2, 9)
        assert.equal(vim.bo.filetype, "python")

        local initial = vim.fn.getpos(".")
        local pos = require("search_in_scope").find_end_pos(initial)

        assert.are.same({0, 10, 13, 0}, pos)
    end)
end)
