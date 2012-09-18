" =============================================================================
" File: taboo.vim
" Description: A little plugin for managing tabs in vim  
" Mantainer: Giacomo Comitti <giacomit at gmail dot com>
" Last Changed: 17 Sep 2012
" Version: 0.0.1
" =============================================================================

" Init ------------------------------------------ {{{

if exists("g:loaded_taboo") || &cp
    finish
endif
let g:loaded_taboo = 1

" }}}

" Initialize variables -------------------------- {{{

if !exists("s:tabs")
    let s:tabs = {}
endif

" used to split surrounding characters given in the same string
if !exists("s:taboo_split_char")
    let s:taboo_split_char = '@'
endif

if !exists("s:taboo_fmt_char")
    let s:taboo_fmt_char = '%'
endif


" }}}

" Initialize default settings ------------------- {{{

" format options:
"
"   displayed name:
"   %f -> file name in normal tab or custom label for renamed tab
"   %F -> path relative to $HOME
"   %a -> absolute path
"   %[n]a -> custom level of path depth
"
"   numbers:
"   %n -> show tab number only on the active tab
"   %N -> show always tab number
"
"   flags:
"   %m -> modified flag
"   %b -> number of buffers opened in a tab
"         (same as windows number)
"

if !exists("g:taboo_format")
    let g:taboo_format = " %n %2a%m "
endif

if !exists("g:taboo_format_renamed")
    let g:taboo_format_renamed = " %n [%f]%m "
endif

if !exists("g:taboo_modified_flag")
    let g:taboo_modified_flag= "*"
endif    

if !exists("g:taboo_close_label")
    let g:taboo_close_label = ''
endif    

if !exists("g:taboo_unnamed_label")
    let g:taboo_unnamed_label = '[no name]'
endif    

" }}}


" TabooTabline ---------------------------------- {{{
function! TabooTabline()
    "call s:update_tabs()

    let tabln = ''
    for i in range(1, tabpagenr('$'))

        let tab = get(s:tabs, i)
        if empty(tab)  " not renamed
            let label_items = s:parse_fmt_str(g:taboo_format)
        else
            let label_items = s:parse_fmt_str(g:taboo_format_renamed)
        endif

        let tabln .= s:expand_fmt_str(i, label_items)
    endfor
     
    let tabln .= '%#TabLineFill#'
    let tabln .= '%=%#TabLine#%999X' . g:taboo_close_label

    return tabln
endfunction
" }}}

" parse_fmt_str --------------------------------- {{{
function! s:parse_fmt_str(str)
    let tokens = []
    let i = 0
    while i < strlen(a:str)
        let pos = match(a:str, '%\(f\|F\|\d\?a\|n\|N\|m\|b\)', i)
        if pos < 0
            call extend(tokens, split(strpart(a:str, i, strlen(a:str) - i), '\zs'))
            let i = strlen(a:str)
        else
            call extend(tokens, split(strpart(a:str, i, pos - i), '\zs'))
            " determne if a number is given as second character
            let flag_len = match(a:str[pos + 1], "[0-9]") >= 0 ? 3 : 2
            if flag_len == 2
                call add(tokens, a:str[pos] . a:str[pos + 1])
                let i = pos + 2
            else
                call add(tokens, a:str[pos] . a:str[pos + 1] . a:str[pos + 2])
                let i = pos + 3
            endif
        endif
    endwhile

    return tokens
endfunction          
" }}}

" expand_fmt ------------------------------------ {{{
function! s:expand_fmt_str(tabnr, items)

    let active_tabnr = tabpagenr()        
    let buflist = tabpagebuflist(a:tabnr)
    let winnr = tabpagewinnr(a:tabnr)
    let last_active_buf = buflist[winnr - 1]
    let label = ""

    " specific highlighting for the current tab
    let label .= a:tabnr == active_tabnr ? '%#TabLineSel#' : '%#TabLine#'
    for i in a:items
        if i[0] == '%' 
             " expand flag
            if i ==# "%m"
                let label .= s:expand_modified_flag(last_active_buf, buflist)
            elseif i == "%f" || i ==# "%a" || match(i, "%[0-9]a") == 0 
                let label .= s:expand_path(i, a:tabnr, last_active_buf)
            elseif i == "%n" " note: == -> case insensitive comparison
                let label .= s:expand_tab_number(i, a:tabnr, active_tabnr)
            elseif i ==# "%b"
                let label .= len(buflist)
            endif
        else
            let label .= i
        endif
    endfor
    return label
endfunction
" }}}

" expand_tab_number ----------------------------- {{{
function! s:expand_tab_number(flag, tabnr, active_tabnr)
    if a:flag ==# "%n" " ==# : case sensitive comparison
        return a:tabnr == a:active_tabnr ? a:tabnr : ''
    else
        return a:tabnr
    endif
endfunction
" }}}

" expand_modified_flag -------------------------- {{{
function! s:expand_modified_flag(last_active_buf, buflist)
    if 1 " FIX How do i get the renamed flag here?
        " add the modified flag if there is some modified buffer into the tab. 
        let buf_mod = 0
        for b in a:buflist
            if getbufvar(b, "&mod")
                let buf_mod = 1
            endif
        endfor
        return buf_mod ? g:taboo_modified_flag : ''
    else
        if getbufvar(last_active_buf, "&mod")
            return g:taboo_modified_flag
        endif
    endif
endfunction
" }}}

" expand_path ----------------------------------- {{{
function! s:expand_path(flag, tabnr, last_active_buf)
    let bn = bufname(a:last_active_buf) " FIX: this is not the active last buffer
    let file_path = fnamemodify(bn, ':p:t')
    let abs_path = fnamemodify(bn, ':p:h')

    if empty(file_path)
        let path = g:taboo_unnamed_label
    else
        let label = get(s:tabs, a:tabnr)
        if empty(label) " not renamed tab
            let path = ""
            if a:flag ==# "%f"
                let path = file_path
            elseif a:flag ==# "%F"
                let path = substitute(abs_path . '/', $HOME, '', '')
                let path = "~" . path . file_path
            elseif a:flag ==# "%a"
                let path = abs_path . "/" . file_path
            elseif match(a:flag, "%[0-9]a") == 0
                let n = a:flag[1]
                let path_tokens = split(abs_path . "/" . file_path, "/")
                let depth = n > len(path_tokens) ? len(path_tokens) : n
                let path = ""
                for i in range(len(path_tokens))
                    let k = len(path_tokens) - n
                    if i >= k
                        let path .= (i > k ? '/' : '') . path_tokens[i]
                    endif
                endfor
            endif
        else
            " renamed tab
            let path = label
        endif
    endif

    return path
endfunction
" }}}


" rename tab {{{
function! s:RenameTab(label)
    call s:add_tab(tabpagenr(), a:label) " TODO: change the name in raname_tab ?
    "refresh tabline
    exec "set showtabline=" . &showtabline 
endfunction

function! s:RenameTabPrompt()
    let label = s:strip(input("New label: "))
    call s:RenameTab(label)
endfunction
" }}}

" open new tab {{{
function! s:OpenNewTab(label)
    exec "w | tabe"
    call s:add_tab(tabpagenr(), a:label)
    "refresh tabline
    exec "set showtabline=" . &showtabline
endfunction

function! s:OpenNewTabPrompt()
    let label = s:strip(input("Tab label: "))
    call s:OpenNewTab(label)
endfunction
" }}}

" reset tab name {{{
function! s:ResetTabName()
    call s:remove_tab(tabpagenr())
    call s:add_tab(tabpagenr(), '')
    "refresh tabline
    exec "set showtabline=" . &showtabline 
endfunction
" }}}

" close tab {{{
function! s:CloseTab()
    if len(s:tabs) > 1
        call s:shift_to_left_tabs_from(tabpagenr()) 
        exec "tabclose"
    else
        echo "Nothing to close!"
    endif
endfunction
" }}}

" shift_to_left_tabs_from {{{
function! s:shift_to_left_tabs_from(currtab)
    let r_tabs = filter(keys(s:tabs), 'v:val > ' . a:currtab)
    for i in r_tabs 
        let t = get(s:tabs, i)
        let s:tabs[i-1] = t
    endfor
    call s:remove_tab(max(keys(s:tabs)))
endfunction
" }}}

" update_tabs {{{
function! s:update_tabs()
    " register every tab when it is created
    let t = get(s:tabs, tabpagenr(), "")
    if empty(t)
        call s:add_tab(tabpagenr(), '')
    endif
endfunction
" }}}


" operations on the tabs list {{{
" =============================================================================

function! s:remove_tab(tabnr)
    unlet s:tabs[a:tabnr]
endfunction

function! s:add_tab(tabnr, label)
    let s:tabs[a:tabnr] = a:label
endfunction
                    
" }}}


" helper functions {{{
" =============================================================================

function! s:strip(str)
    return substitute(a:str, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

" }}}


"command! -bang -nargs=1 TabooRenameTab call s:RenameTab(<q-args>)
command! -bang -nargs=0 TabooRenameTabPrompt call s:RenameTabPrompt()
"command! -bang -nargs=1 TabooOpenTab call s:OpenNewTab(<q-args>)
command! -bang -nargs=0 TabooOpenTabPrompt call s:OpenNewTabPrompt()
command! -bang -nargs=0 TabooCloseTab call s:CloseTab()
command! -bang -nargs=0 TabooResetTabName call s:ResetTabName()
command! -bang -nargs=0 Test echo s:tabs

augroup taboo
    au TabEnter * call s:update_tabs() 
augroup END




