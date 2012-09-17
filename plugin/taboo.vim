" =============================================================================
" File: taboo.vim
" Description: A little plugin for customizing and renaming tabs  
" Mantainer: Giacomo Comitti <giacomit at gmail dot com>
" Last Changed: 17 Sep 2012
" Version: 0.0.2
" =============================================================================

" Init --------------------------- {{{

if exists("g:loaded_taboo") || &cp
    finish
endif
let g:loaded_taboo = 1

" }}}

" Initialize variables ----------- {{{

if !exists("s:tabs_register")
    let s:tabs_register = {}
endif

" used to split surrounding characters given in the same string
if !exists("s:taboo_split_char")
    let s:taboo_split_char = '@'
endif

if !exists("s:taboo_fmt_char")
    let s:taboo_fmt_char = '%'
endif


" }}}

" Initialize default settings ---- {{{

" format options:
"
"   displayed name:
"   %f -> file name
"   %F -> path relative to $HOME
"   %a -> absolute path
"
"   numbers:
"   %n -> show tab number only on the active tab
"   %N -> show always tab number
"
"   flags:
"   %m -> modified flag

if !exists("g:taboo_format")
    let g:taboo_format = "%f%m"
endif

if !exists("g:taboo_format_renamed")
    let g:taboo_format_renamed = "[%f]%m"
endif

if !exists("g:taboo_modified_flag")
    let g:taboo_modified_flag= "*"
endif    

 if !exists("g:taboo_display_close_label")
    let g:taboo_display_close_label = 1
endif 

if !exists("g:taboo_close_label")
    let g:taboo_close_label = 'x '
endif    

if !exists("g:taboo_unnamed_label")
    let g:taboo_unnamed_label = '[no name]'
endif    

" }}}


" TabooTabline ------------------- {{{
" This function will be called inside the terminal

function! TabooTabline()
    call s:updateRegisteredTabs()

    let tabln = ''
    for i in range(1, tabpagenr('$'))

        let tab = get(s:tabs_register, i)
        if tab == "0" " not renamed
            let label_items = s:parse_fmt_str(g:taboo_format)
        else
            let label_items = s:parse_fmt_str(g:taboo_format_renamed)
        endif

        let tabln .= s:expand_fmt(i, label_items)
    endfor
     
    let tabln .= '%#TabLineFill#'
    if g:taboo_display_close_label
        let tabln .= s:expand_close_label()
    endif     

    return tabln
endfunction
" }}}

" parse_fmt_str ------------------ {{{
" %s at the end of the string a and orphans %s such as the first % of '%%f'
" are ignored (FIX??)
function! s:parse_fmt_str(str)
    let items = []
    for i in range(strlen(a:str)) 
        let c = a:str[i]
        if i == 0 && c != s:taboo_fmt_char
            call add(items, c)
        elseif a:str[i-1] != s:taboo_fmt_char && c != s:taboo_fmt_char
            call add(items, c)
        elseif a:str[i-1] == s:taboo_fmt_char && c != s:taboo_fmt_char
            call add(items, s:taboo_fmt_char . c)
        endif
    endfor
    return items
endfunction
" }}}

" expand_ftm --------------------- {{{
function! s:expand_fmt(tabnr, items)

    let active_tabnr = tabpagenr()        
    let buflist = tabpagebuflist(a:tabnr)
    let winnr = tabpagewinnr(a:tabnr)
    let label = ""

    " specific highlighting for the current tab
    let label .= a:tabnr == active_tabnr ? '%#TabLineSel#' : '%#TabLine#'
    let label .= " "
    for i in a:items
        if i[0] == '%' 
             " expand flag
            if i ==# "%m"
                let label .= s:expand_modified_flag(buflist)
            elseif i == "%f" || i ==# "%a" 
                let label .= s:expand_path(i, a:tabnr, buflist)
            elseif i == "%n" " note: == -> case insensitive comparison
                let label .= s:expand_tab_number(i, a:tabnr, active_tabnr)
            endif
        else
            let label .= i
        endif

    endfor
    let label .= " "

    return label
endfunction
" }}}

" expand_tab_number -------------- {{{
function! s:expand_tab_number(flag, tabnr, active_tabnr)
    echom a:flag
    if a:flag ==# "%n" " ==# : case sensitive comparison
        return a:tabnr == a:active_tabnr ? a:tabnr : ''
    else
        return a:tabnr
    endif
endfunction
" }}}

" expand_modified_flag ----------- {{{
function! s:expand_modified_flag(buflist)
    " add the modified flag if there is some modified buffer into the tab. 
    let buf_mod = 0
    for b in a:buflist
        if getbufvar(b, "&mod")
            let buf_mod = 1
        endif
    endfor
    return buf_mod ? g:taboo_modified_flag : ''
endfunction
" }}}

" expand_path -------------------- {{{
function! s:expand_path(flag, tabnr, buflist)
    let bn = bufname(a:buflist[0])
    let file_path = fnamemodify(bn, ':p:t')
    let abs_path = fnamemodify(bn, ':p:h')

    let tab = get(s:tabs_register, a:tabnr)
    if tab == "0" " not renamed
        let path = ""
        if a:flag ==# "%f"
            let path = file_path
        elseif a:flag ==# "%F"
            let path = substitute(abs_path . '/', $HOME, '', '')
            let path = "~" . path . file_path
        elseif a:flag ==# "%a"
            let path = abs_path . "/" . file_path
        endif

        if empty(path)
            let path = g:tab_unnamed_label
        endif
    else
        let path = tab
    endif

    return path
endfunction
" }}}

" expand_close_label ------------- {{{
function! s:expand_close_label()
    if tabpagenr('$') > 1
        return '%=%#TabLine#%999X' . g:taboo_close_label
    endif                
endfunction
" }}}        

function! s:RenameTab(label)
    call s:register_curr_tab(a:label) " TODO: change the name in raname_tab ?
    set showtabline=1 " refresh the tabline TODO: find a better solution
endfunction

function! s:RenameTabPrompt()
    let label = s:strip(input("New label: "))
    call s:RenameTab(label)
endfunction

function! s:OpenNewTab(label)
    exec "w | tabe"
    call s:register_curr_tab(a:label)
    set showtabline=1 " refresh tabline. TODO: find a better solution
endfunction

function! s:OpenNewTabPrompt()
    let label = s:strip(input("Tab label: "))
    call s:OpenNewTab(label)
endfunction

function! s:ResetTabName()
    let curr_tab = tabpagenr()
    call s:unregister_tab(curr_tab)
    set showtabline=1 " refresh tabline. TODO: find a better solution
endfunction

function! s:CloseTab()
    " TODO
    " this function must ensure that when i tab is closed
    " all the registered tabs (renamed tabs) will gets updated properly
endfunction

" mmh, TODO: revisit
function! s:updateRegisteredTabs()
    for i in keys(s:tabs_register)
        if i > tabpagenr('$')
            " the tab # i does not exist anymore: remove it
            call s:unregister_tab(i)
        endif
    endfor
endfunction


" operations on the tabs register
" =============================================================================

function! s:unregister_tab(tabnr)
    unlet s:tabs_register[a:tabnr]
endfunction

function! s:register_tab(tabnr, label)
    let s:tabs_register[a:tabnr] = a:label
endfunction

function! s:register_curr_tab(label)
    let curr_tab = tabpagenr()
    call s:register_tab(curr_tab, a:label)
endfunction


" helper functions
" =============================================================================

function! s:strip(str)
    return substitute(a:str, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction


"command! -bang -nargs=1 TabooRenameTab call s:RenameTab(<q-args>)
command! -bang -nargs=0 TabooRenameTabPrompt call s:RenameTabPrompt()
"command! -bang -nargs=1 TabooOpenTab call s:OpenNewTab(<q-args>)
command! -bang -nargs=0 TabooOpenTabPrompt call s:OpenNewTabPrompt()
command! -bang -nargs=0 TabooResetTabName call s:ResetTabName()
"command! -bang -nargs=0 TabooCloseTab call s:CloseTab()
command! -bang -nargs=1 TabooTest echo s:tabs_register

augroup taboo
    " TODO: use directly remove_tab_from_register ?
    au TabLeave * call s:updateRegisteredTabs() 
augroup END




