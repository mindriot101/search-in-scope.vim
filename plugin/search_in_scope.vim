if exists("g:loaded_search_in_scope") | finish | endif

function! SearchInScope()
    lua require("search_in_scope").search_in_scope()
endfunction

let g:loaded_search_in_scope = 1
