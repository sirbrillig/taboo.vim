" =============================================================================
" File: taboo.vim
" Description: A little plugin for managing tabs in terminal vim  
" Mantainer: Giacomo Comitti (https://github.com/gcmt)
" Url: https://github.com/gcmt/taboo.vim
" Last Changed: 19 Sep 2012
" Version: 0.1.0
" =============================================================================

" Init ------------------------------------------ {{{

if exists("g:loaded_taboo") || &cp
    finish
endif
let g:loaded_taboo = 1

" }}}

" Initialize private variables ------------------ {{{

" where all tabs are stored
if !exists("s:tabs")
    let s:tabs = {}
endif

" the special character used to recognize a special flags in the format string
if !exists("s:fmt_char")
    let s:fmt_char = '%'
endif

if !exists("s:last_number_of_tabs")
    let s:last_number_of_tabs = tabpagenr()
endif

if !exists("s:staging_tab")
    let s:staging_tab = 0
endif
" }}}

" Initialize default settings ------------------- {{{
"
" :help taboo.txt for format items
if !exists("g:taboo_format")
    let g:taboo_format = " %n %f%m "
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

if !exists("g:taboo_enable_mappings")
    let g:taboo_enable_mappings = 1
endif           
 
if !exists("g:taboo_open_empty_tab")
    let g:taboo_open_empty_tab= 1
endif     
" }}}


" CONSTRUCT THE [GUI]TABLINE
" =============================================================================

" TabooTabline ---------------------------------- {{{
" This function construct the tabline string (only in terminal vim)
" The whole tabline is constructed at once.
"
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

        let tabln .= i == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#'
        let tabln .= s:expand_fmt_str(i, label_items)
    endfor
     
    let tabln .= '%#TabLineFill#'
    let tabln .= '%=%#TabLine#%999X' . g:taboo_close_label

    return tabln
endfunction
" }}}

" TabooGuiTabLabel --------------------------------- {{{
" Construct a single tab label at once
"
function! TabooGuiTabLabel()
    let label = ""
    let tabnr = v:lnum

    let t = get(s:tabs, tabnr)
    if empty(t)  " not renamed
        let label_items = s:parse_fmt_str(g:taboo_format)
    else
        let label_items = s:parse_fmt_str(g:taboo_format_renamed)
    endif
    let label = s:expand_fmt_str(tabnr, label_items)

    return label
endfunction  
" }}}

" parse_fmt_str --------------------------------- {{{
" To parse the format string and return a list of tokens, where a token is
" a single character or a flag such as %f or %2a
" Example:
"   parse_fmt_str("%n %tab") -> ['%n', ' ', '%', 't', 'a', 'b'] 
"
function! s:parse_fmt_str(str)
    let tokens = []
    let i = 0
    while i < strlen(a:str)
        let pos = match(a:str, s:fmt_char . '\(f\|F\|\d\?a\|n\|N\|m\|w\)', i)
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
" To expand flags contained in the `items` list of tokes into their respective
" meanings.
"
function! s:expand_fmt_str(tabnr, items)

    let active_tabnr = tabpagenr()        
    let buflist = tabpagebuflist(a:tabnr)
    let winnr = tabpagewinnr(a:tabnr)
    let last_active_buf = buflist[winnr - 1]
    let label = ""

    " specific highlighting for the current tab
    for i in a:items
        if i[0] == s:fmt_char 
            let f = strpart(i, 1)  " remove the fmt_char
            if i ==# "m"
                let label .= s:expand_modified_flag(last_active_buf, buflist)
            elseif f == "f" || f ==# "a" || match(f, "[0-9]a") == 0 
                let label .= s:expand_path(f, a:tabnr, last_active_buf)
            elseif f == "n" " note: == -> case insensitive comparison
                let label .= s:expand_tab_number(f, a:tabnr, active_tabnr)
            elseif f ==# "w"
                let label .= tabpagewinnr(tabnr, '$')
            endif
        else
            let label .= i
        endif
    endfor
    return label
endfunction
" }}}

" expand_tab_number ----------------------------- {{{
"
function! s:expand_tab_number(flag, tabnr, active_tabnr)
    if a:flag ==# "n" " ==# : case sensitive comparison
        return a:tabnr == a:active_tabnr ? a:tabnr : ''
    else
        return a:tabnr
    endif
endfunction
" }}}

" expand_modified_flag -------------------------- {{{
"
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
"
function! s:expand_path(flag, tabnr, last_active_buf)
    let bn = bufname(a:last_active_buf)
    let file_path = fnamemodify(bn, ':p:t')
    let abs_path = fnamemodify(bn, ':p:h')
    let label = get(s:tabs, a:tabnr)

    if empty(label) " not renamed tab
        if empty(file_path)
            let path = g:taboo_unnamed_label
        else   
            let path = ""
            if a:flag ==# "f"
                let path = file_path
            elseif a:flag ==# "F"
                let path = substitute(abs_path . '/', $HOME, '', '')
                let path = "~" . path . file_path
            elseif a:flag ==# "a"
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
        endif
    else
        " renamed tab
        let path = label
    endif

    return path
endfunction
" }}}


" COMMANDS FUNCTIONS
" =============================================================================

" rename tab ------------------------------------ {{{
" To rename the current tab.
"
function! s:RenameTab(label)
    call s:add_tab(tabpagenr(), a:label) " TODO: change the name in raname_tab ?
    call s:tabline_refresh()
endfunction

function! s:RenameTabPrompt()
    let label = s:strip(input("New label: "))
    call s:RenameTab(label)
endfunction

" }}}

" open new tab ---------------------------------- {{{
" To open a new tab with a custom name.
"
function! s:OpenNewTab(label)
    let save = empty(bufname('%')) ? '' : 'w | ' 
    exec save . "tabe " . (g:taboo_open_empty_tab ? '' : '%') 
    call s:add_tab(tabpagenr(), a:label)
    call s:tabline_refresh()
endfunction

function! s:OpenNewTabPrompt()
    let label = s:strip(input("Tab label: "))
    call s:OpenNewTab(label)
endfunction
" }}}

" reset tab name -------------------------------- {{{
" If the tab has been renamed the custom label is removed.
"
function! s:ResetTabName()
    call s:remove_tab(tabpagenr())
    call s:add_tab(tabpagenr(), '')
    "refresh tabline
    call s:tabline_refresh()
endfunction
" }}}


" HELPER FUNCTIONS
" =============================================================================

" remove_tab ------------------------------------ {{{
function! s:remove_tab(tabnr)
    unlet s:tabs[a:tabnr]
endfunction
" }}}

" add_tab --------------------------------------- {{{
function! s:add_tab(tabnr, label)
    let s:tabs[a:tabnr] = a:label
endfunction                    
" }}}

" strip ----------------------------------------- {{{
" To strip surrounding whitespaces and tabs from a string. 
"
function! s:strip(str)
    return substitute(a:str, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction
" }}}

" tabline_refresh ------------------------------- {{{
"
function! s:tabline_refresh()
    exec "set showtabline=" . &showtabline 
endfunction!
" }}}

" shift_to_left_tabs_from ----------------------- {{{
" To update the tab list when a tab at any position is closed. When a tab is
" closed, all tabs on its right gets shifted to fill the old tab position. This
" function ensure this update in the state of the tabline gets reflected also
" in the tab list owned by the taboo plugin. 
"
function! s:shift_to_left_tabs_from(currtab)
    let r_tabs = filter(keys(s:tabs), 'v:val >= ' . a:currtab)
    for i in r_tabs 
        let t = get(s:tabs, i)
        let s:tabs[i-1] = t
    endfor
endfunction
" }}}

" update_tabs {{{
" To 'register' a tab whenever it is created but only if it is not already
" registered.
"
function! s:update_tabs()
    " add a tab when it is created
    let t = get(s:tabs, tabpagenr(), "")
    if empty(t)
        call s:add_tab(tabpagenr(), '')
    endif

    " detect if a tab has been closed. If so delete it from the tab list and 
    " update all others tab
    let cond = s:last_number_of_tabs > tabpagenr('$')
    if !empty(s:staging_tab) && cond
        call s:shift_to_left_tabs_from(s:staging_tab + 1)
        call s:remove_tab(max(keys(s:tabs)))
    endif
    let s:last_number_of_tabs = tabpagenr('$')
endfunction

function! s:stage_tab_for_closing(tabnr)
    let s:staging_tab = a:tabnr
endfunction
" }}}


" COMMANDS
" =============================================================================

command! -nargs=1 TabooRenameTab call s:RenameTab(<q-args>)
command! -nargs=1 TabooOpenTab call s:OpenNewTab(<q-args>)
command! -nargs=0 TabooRenameTabPrompt call s:RenameTabPrompt()
command! -nargs=0 TabooOpenTabPrompt call s:OpenNewTabPrompt()
command! -nargs=0 TabooResetName call s:ResetTabName()
command! Test echo s:tabs


" MAPPINGS
" =============================================================================

if g:taboo_enable_mappings
    nnoremap <silent> <leader>tt :TabooRenameTabPrompt<CR>
    nnoremap <silent> <leader>to :TabooOpenTabPrompt<CR>
    nnoremap <silent> <leader>td :TabooCloseTab<CR>
    nnoremap <silent> <leader>tr :TabooResetName<CR>
endif


" AUTOCOMMANDS
" =============================================================================

augroup taboo
    " when I enter vim the TabEnter event is not triggered
    au VimEnter * call s:update_tabs()
    au TabEnter * call s:update_tabs() 
    au TabLeave * call s:stage_tab_for_closing(tabpagenr()) 
augroup END




