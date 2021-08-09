# search-in-scope.vim

Search within a scope.

This plugin works with files that define scopes with braces (e.g. C, php, rust) as well as files that define scopes with
indentation (yaml, python).

## Setup

For example with packer:

```lua
require('packer').startup(function(use)
    use 'mindriot101/search-in-scope.vim'
end)

require('search_in_scope').setup({
    -- example keybinding
    bind = "<leader>S",
})
```

Then hit the `<leader>S` keyboard combination. This will set the command buffer up for searching within the scope as
defined by the filetype.
