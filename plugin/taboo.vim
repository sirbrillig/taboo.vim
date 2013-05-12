" =============================================================================
" File: taboo.vim
" Description: A little plugin for managing tabs in vim
" Mantainer: Giacomo Comitti (https://github.com/gcmt)
" Url: https://github.com/gcmt/taboo.vim
" License: MIT
" Version: 1.4
" Last Changed: May 11, 2013
" =============================================================================


" Init ------------------------------------------ {{{

if exists("g:loaded_taboo") || &cp || v:version < 703
    finish
endif
let g:loaded_taboo = 1

" }}}

" Initialize internal variables ------------------ {{{

" the special character used to recognize a special flags in the format string
let s:fmt_char = get(s:, "fmt_char", "%")

" dictionary of the form: {tab_number: label, ..}. This is populated when Vim
" exits.
let g:Taboo_tabs = get(g:, "Taboo_tabs", "")

" }}}

" Initialize default settings ------------------- {{{

let g:taboo_tab_format = get(g:, "taboo_tab_format", " %f%m ")
let g:taboo_renamed_tab_format = get(g:, "taboo_renamed_tab_format", " [%f]%m ")
let g:taboo_modified_tab_flag= get(g:, "taboo_modified_tab_flag", "*")
let g:taboo_close_tabs_label = get(g:, "taboo_close_tabs_label", "")
let g:taboo_unnamed_tab_label = get(g:, "taboo_unnamed_tab_label", "[no name]")
let g:taboo_open_empty_tab = get(g:, "taboo_open_empty_tab", 1)

" }}}


" CONSTRUCT THE TABLINE
" =============================================================================

" TabooTabline ---------------------------------- {{{
" This function construct the tabline string for terminal vim
" The whole tabline is constructed at once.
"
function! TabooTabline()
    let tabln = ''

        let label = gettabvar(i, "taboo_tab_label")
        if empty(label)  " not renamed
    for i in s:tabs()
            let label_items = s:parse_fmt_str(g:taboo_tab_format)
        else
            let label_items = s:parse_fmt_str(g:taboo_renamed_tab_format)
        endif

        let tabln .= i == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#'
        let tabln .= s:expand_fmt_str(i, label_items)
    endfor

    let tabln .= '%#TabLineFill#'
    let tabln .= '%=%#TabLine#%999X' . g:taboo_close_tabs_label

    return tabln
endfunction
" }}}

" TabooGuiLabel --------------------------------- {{{
" This function construct a single tab label for gui vim
function! TabooGuiLabel()

    let label = gettabvar(v:lnum, "taboo_tab_label")
    if empty(label)  " not renamed
        let label_items = s:parse_fmt_str(g:taboo_tab_format)
    else
        let label_items = s:parse_fmt_str(g:taboo_renamed_tab_format)
    endif

    return s:expand_fmt_str(v:lnum, label_items)

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

" expand_fmt_str -------------------------------- {{{
" To expand flags contained in the `items` list of tokes into their respective
" meanings.
"
function! s:expand_fmt_str(tabnr, items)

    let buflist = tabpagebuflist(a:tabnr)
    let winnr = tabpagewinnr(a:tabnr)
    let last_active_buf = buflist[winnr - 1]
    let label = ""

    " specific highlighting for the current tab
    for i in a:items
        if i[0] == s:fmt_char
            let f = strpart(i, 1)  " remove the fmt_char
            if f ==# "m"
                let label .= s:expand_modified_flag(buflist)
            elseif f == "f" || f ==# "a" || match(f, "[0-9]a") == 0
                let label .= s:expand_path(f, a:tabnr, last_active_buf)
            elseif f == "n" " note: == -> case insensitive comparison
                let label .= s:expand_tab_number(f, a:tabnr, tabpagenr())
            elseif f ==# "w"
                let label .= tabpagewinnr(a:tabnr, '$')
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
function! s:expand_modified_flag(buflist)
    for b in a:buflist
        if getbufvar(b, "&mod")
            return g:taboo_modified_tab_flag
        endif
    endfor
    return ''
endfunction
" }}}

" expand_path ----------------------------------- {{{
"
function! s:expand_path(flag, tabnr, last_active_buf)

    let bn = bufname(a:last_active_buf)
    let file_path = fnamemodify(bn, ':p:t')
    let abs_path = fnamemodify(bn, ':p:h')
    let label = gettabvar(a:tabnr, 'taboo_tab_label')

    if empty(label) " not renamed tab
        if empty(file_path)
            let path = g:taboo_unnamed_tab_label
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


" INTERFACE FUNCTIONS
" =============================================================================

" rename tab ------------------------------------ {{{
" To rename the current tab.
function! s:RenameTab(label)
    call settabvar(tabpagenr(), "taboo_tab_label", a:label)
    call s:refresh_tabline()
endfunction
" }}}

" open new tab ---------------------------------- {{{
" To open a new tab with a custom name.
function! s:OpenNewTab(label)
    exec "tabe! " . (g:taboo_open_empty_tab ? '' : '%')
    call s:RenameTab(a:label)
endfunction
" }}}

" reset tab name -------------------------------- {{{
" If the tab has been renamed the custom label is removed.
function! s:ResetTabName()
    call settabvar(tabpagenr(), "taboo_tab_label", "")
    call s:refresh_tabline()
endfunction
" }}}


" HELPER FUNCTIONS
" =============================================================================

" tabs {{{
function! s:tabs()
    return range(1, tabpagenr('$'))
endfunction
" }}}

" refresh_tabline ------------------------------- {{{
function! s:refresh_tabline()
    if exists("g:SessionLoad")
        return
    endif
    let g:Taboo_tabs = ""
        if !empty(gettabvar(i, "taboo_tab_label"))
            let g:Taboo_tabs .= i."\t".gettabvar(i, "taboo_tab_label")."\n"
    for i in s:tabs()
        endif
    endfor
    exec "set showtabline=" . &showtabline
endfunction!
" }}}

" extract_tabs_from_str {{{
function! s:extract_tabs_from_str()
    let tabs = {}
    let l = split(get(g:, "Taboo_tabs", ""), "\n")
    for ln in l
        let tokens = split(ln, "\t")
        let tabs[tokens[0]] = tokens[1]
    endfor
    return tabs
endfunction
" }}}

" restore_tabs {{{
function! s:restore_tabs()
    if !empty(g:Taboo_tabs)
        let tabs = s:extract_tabs_from_str()
            call settabvar(i, "taboo_tab_label", get(tabs, i, ""))
        for i in s:tabs()
            call settabvar(i, "taboo_tab_name", get(tabs, i, ""))
        endfor
    endif
endfunction
" }}}


" COMMANDS
" =============================================================================

command! -nargs=1 TabooRename call s:RenameTab(<q-args>)
command! -nargs=1 TabooOpen call s:OpenNewTab(<q-args>)
command! -nargs=0 TabooReset call s:ResetTabName()


" AUTOCOMMANDS
" =============================================================================

augroup taboo
    au!
    au SessionLoadPost * call s:restore_tabs()
    au TabLeave,TabEnter * call s:refresh_tabline()
    au VimEnter * set tabline=%!TabooTabline()
    au VimEnter * if has('gui_running')|set guitablabel=%!TabooGuiLabel()|endif
augroup END
