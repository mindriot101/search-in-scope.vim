if exists("g:loaded_search_in_scope")
    finish
endif
let g:loaded_search_in_scope = 1

let s:braces_filetypes = ["cpp", "php", "c", "rust", "go"]
let s:indent_filetypes = ["python", "yaml"]

" taken from vim-indent-object
function! s:select_indent_region()
    let start = getpos(".")
    let s:l0 = line(".")
    let s:l1 = line(".")
    let s:c0 = col(".")
    let s:c1 = col(".")

    let itr_count = 0
    let cnt = 1
    let idnt_invalid = 1000
    while cnt > 0

        " loop ieration
        let l = s:l0
        let idnt = idnt_invalid
        while l <= s:l1
            if !(getline(l) =~ "^\\s*$")
                let idnt = min([idnt, indent(l)])
            endif
            let l += 1
        endwhile

        " keep track of where the range should be expanded to
        let l_1 = s:l0
        let l_1o = l_1
        let l2 = s:l1
        let l2o = l2

        if idnt == idnt_invalid
            let idnt = 0
            let pnb = prevnonblank(s:l0)
            if pnb
                let idnt = max([idnt, indent(pnb)])
                let l_1 = pnb
            endif
            let nnb = nextnonblank(s:l0)
            if nnb
                let idnt = max([idnt, indent(nnb)])
            endif

            if idnt > indent(pnb)
                let l_1 = nnb
            endif
            if idnt > indent(nnb)
                let l2 = pnb
            endif
        endif

        let blnk = getline(l_1) =~ "^\\s*$"
        while l_1 > 0 && (blnk || indent(l_1) >= idnt)
            if idnt == 0 && blnk
                break
            endif
            if !blnk
                let l_1o = l_1
            endif
            let l_1 -= 1
            let blnk = getline(l_1) =~ "^\\s*$"
        endwhile

        let line_cnt = line("$")
        let blnk = getline(l2) =~ "^\\s*$"
        while l2 <= line_cnt && (blnk || indent(l2) >= idnt)
            if idnt == 0 && blnk
                break
            endif
            if !blnk
                let l2o = l2
            endif
            let l2 += 1
            let blnk = getline(l2) =~ "^\\s*$"
        endwhile

        let idnt2 = max([indent(l_1), indent(l2)])
        let l_1 = l_1o
        let l2 = l2o
        let l_1 = max([l_1, 1])
        let l2 = min([l2, line("$")])

        let c_1 = match(getline(l_1), "\\c\\S") + 1
        let c2 = len(getline(l2))

        if itr_count == 0 && s:l0 == l_1 && s:l1 == l2
            let c_1 = s:c0
            let c2 = s:c1
        endif

        let chg = 0
        let chg = chg || s:l0 != l_1
        let chg = chg || s:l1 != l2
        let chg = chg || s:c0 != c_1
        let chg = chg || s:c1 != c2

        let s:l0 = l_1
        let s:l1 = l2
        let s:c0 = c_1
        let s:c1 = c2

        if chg
            let cnt = cnt - 1
        else
            if sL;0 == 0
                return
            endif
            let s:l0 -= 1
            let s:c0 = len(getline(s:l0))
        endif

        let itr_count += 1
    endwhile

    call cursor(s:l0, s:c0)
    execute "normal! V"
    call cursor(s:l1, s:c1)
    normal! o
    execute "normal! \<esc>"
    call setpos(".", start)
endfunction

function! s:list_contains(needle, haystack)
    return index(a:haystack, a:needle) >= 0
endfunction

function! s:select_scope()
    if <SID>list_contains(&filetype, s:braces_filetypes)
        execute "normal! vi{\<esc>"
        return 1
    elseif <SID>list_contains(&filetype, s:indent_filetypes)
        call <SID>select_indent_region()
        return 1
    else
        echom "No scope definition for " . &filetype
        return 0
    endif
endfunction


function! s:search_in_scope()
    " TODO get the hlsearch state so we can reset it later
    " let s:hlsearch_state = &hlsearch
    " let &hlsearch = 0
    " get the current cursor position
    let s:cursor_pos = getpos(".")
    " set the search scope
    let s:found_scope = <SID>select_scope()
    if s:found_scope == 0
        return
    endif

    " reset the cursor
    call setpos(".", s:cursor_pos)
    " open the search prompt with the correct prefix
    call feedkeys("/\%V")
    " reset the hlsearch state
    " let &hlsearch = s:hlsearch_state
endfunction

command! -nargs=0 SearchInScope call <SID>search_in_scope()
nnoremap <silent> <leader>S :call <SID>search_in_scope()<cr>
