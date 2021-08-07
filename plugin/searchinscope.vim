function s:search_in_scope()
    " TODO get the hlsearch state so we can reset it later
    " let s:hlsearch_state = &hlsearch
    " let &hlsearch = 0
    " get the current cursor position
    let s:cursor_pos = getpos(".")
    " set the search scope
    execute "normal! vi{\<esc>"
    " reset the cursor
    call setpos(".", s:cursor_pos)
    " open the search prompt with the correct prefix
    call feedkeys("/\%V")
    " reset the hlsearch state
    " let &hlsearch = s:hlsearch_state
endfunction

command! -nargs=0 SearchInScope call <SID>search_in_scope()
nnoremap <silent> <leader>S :call <SID>search_in_scope()<cr>
