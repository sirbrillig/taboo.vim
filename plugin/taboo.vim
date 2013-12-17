" =============================================================================
" File: taboo.vim
" Description: A little plugin for managing tabs in vim
" Mantainer: Giacomo Comitti (https://github.com/gcmt)
" Url: https://github.com/gcmt/taboo.vim
" License: MIT
" Version: 1.4
" Last Changed: May 12, 2013
" =============================================================================


" Init ------------------------------------------ {{{

if exists("g:loaded_taboo") || &cp || v:version < 703
    finish
endif
let g:loaded_taboo = 1

" }}}

" Initialize internal variables ------------------ {{{

" wher custom tab names get stored (format: 'TABNUM\tTABNAME\n ...')
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


" FUNCTIONS FOR CONSTRUCTING THE TABLINE
" =============================================================================

" TabooTabline ---------------------------------- {{{
" This function construct the tabline string for terminal vim
" The whole tabline is constructed at once.
function! TabooTabline()

    let tabln = ''  " tabline string

    for i in s:tabs()

        let label = gettabvar(i, "taboo_tab_name")
        if empty(label)
            " not renamed tab
            let label_items = s:parse_fmt_str(g:taboo_tab_format)
        else
            " renamed tab
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
" This is automatically called by Vim for each tab.
function! TabooGuiLabel()

    let label = gettabvar(v:lnum, "taboo_tab_name")
    if empty(label)
        " not renamed tab
        let label_items = s:parse_fmt_str(g:taboo_tab_format)
    else
        " renamed tab
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
function! s:parse_fmt_str(str)

    let tokens = []
    let i = 0

    while i < strlen(a:str)
        let pos = match(a:str, "%" . '\(f\|F\|T\|t\|[\d]\?a\|n\|N\|m\|w\)', i)
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
function! s:expand_fmt_str(tabnr, items)

    let buflist = tabpagebuflist(a:tabnr)
    let winnr = tabpagewinnr(a:tabnr)
    let last_active_buf = buflist[winnr - 1]
    let label = ""

    " specific highlighting for the current tab
    for i in a:items

        if i[0] == "%"
            let f = strpart(i, 1) " remove the '%' charater from the string
            if f ==# "m"
                let label .= s:expand_modified_flag(buflist)
            elseif f == "f" || f == "t" || f ==# "a" || match(f, "[0-9]a") == 0
                let label .= s:expand_path(f, a:tabnr, last_active_buf)
            elseif f ==? "n" " note: == performs case insensitive comparison
                let label .= s:expand_tab_number(f, a:tabnr)
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
function! s:expand_tab_number(flag, tabnr)
    if a:flag ==# "n" " ==# : case sensitive comparison
        return a:tabnr == tabpagenr() ? a:tabnr : ''
    else
        return a:tabnr
    endif
endfunction
" }}}

" expand_modified_flag -------------------------- {{{
function! s:expand_modified_flag(buflist)
    for b in a:buflist
        if getbufvar(b, "&mod")
            return g:taboo_modified_tab_flag
        endif
    endfor
    return ''
endfunction
" }}}

" truncate_path --------------------------------- {{{
" To truncate a path to fit within the window width. Assumes equal width per
" tab, which is not neccessarily the most efficient use of space.
function! s:truncate_path(path, fname, tabnr, flag)
  let path_tokens = split(a:path, "/")

  " the total amount of characters we can fit
  let available_chars = &columns

  " the length of the rest of the format string apart from this flag
  let remaining_format_str = substitute(g:taboo_tab_format, '%' . a:flag, '', 'g')
  let extra_chars_per_tab = len(s:expand_fmt_str(a:tabnr, s:parse_fmt_str(remaining_format_str)))

  " the available characters divided by the number of tabs minus
  " extra characters, the length of the filename, and the pathname
  " separators gives us the number of characters available per tab
  let chars_per_tab = (available_chars / tabpagenr("$")) - extra_chars_per_tab - len(a:fname) - len(path_tokens) - 1

  " sometimes there just isn't enough space for the path
  if chars_per_tab <# 1
    return a:fname
  endif

  " sometimes there is no need to truncate at all
  let full_path = a:path . "/" . a:fname
  let chars_to_remove = len(full_path) - chars_per_tab
  if chars_to_remove <=# 0
    return full_path
  endif

  " the available characters per tab divided by the number of
  " tokens gives us the number of available characters per token
  let chars_per_token = (chars_per_tab / len(path_tokens))
  if chars_per_token <# 1
    let chars_per_token = 1
  endif

  " truncate each path token to be no larger than the number of
  " available characters per token
  let path_tokens = map(path_tokens, 'strpart(v:val, 0, chars_per_token)')
  return join(path_tokens, "/") . "/" . a:fname
endfunction
" }}}

" expand_path ----------------------------------- {{{
function! s:expand_path(flag, tabnr, last_active_buf)

    let bn = bufname(a:last_active_buf)
    let fname = fnamemodify(bn, ':p:t')
    let basedir = fnamemodify(bn, ':p:h')
    let label = gettabvar(a:tabnr, 'taboo_tab_name')

    if empty(label)
        " not renamed tab
        if empty(fname)
            " unnamed buffer, usually an empty brand new buffer
            let path = g:taboo_unnamed_tab_label
        else
            let path = ""
            if a:flag ==# "f"
                " just the file name
                let path = fname
            elseif a:flag ==# "t"
                " truncated absolute path
                let path = s:truncate_path(basedir, fname, a:tabnr, a:flag)
            elseif a:flag ==# "T"
                " truncated relative path
                let path = s:truncate_path(fnamemodify(bn, ':.:h'), fname, a:tabnr, a:flag)
            elseif a:flag ==# "F"
                " path relative to $HOME (if possible)
                let path = substitute(basedir, $HOME, '~', '')
                if path == '~'
                    let path = path . '/'
                endif
                let path = path . fname
            elseif a:flag ==# "a"
                " absolute path
                let path = basedir . "/" . fname
            elseif match(a:flag, "[0-9]a") == 0
                " custom level of path depth
                let path = substitute(basedir, $HOME, '~', '')
                let path_tokens = split(path, "/")
                let _path = []
                let n = a:flag[0] > len(path_tokens) ? len(path_tokens) : a:flag[0]
                for t in reverse(path_tokens)
                    if n > 0
                        let _path = insert(_path, t, 0)
                    endif
                    let n -= 1
                endfor
                let path = join(_path, "/") . "/" . fname
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
    let t:taboo_tab_name = a:label
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
" If the tab has been renamed the custom name is removed.
function! s:ResetTabName()
    let t:taboo_tab_name = ""
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
    for i in s:tabs()
        if !empty(gettabvar(i, "taboo_tab_name"))
            let g:Taboo_tabs .= i."\t".gettabvar(i, "taboo_tab_name")."\n"
        endif
    endfor
    exec "set showtabline=" . &showtabline
endfunction!
" }}}

" extract_tabs_from_str {{{
function! s:extract_tabs_from_str(str)
    let tabs = {}
    let lines = split(a:str, "\n")
    for ln in lines
        let tokens = split(ln, "\t")
        let tabs[tokens[0]] = tokens[1]
    endfor
    return tabs
endfunction
" }}}

" restore_tabs {{{
function! s:restore_tabs()
    if !empty(g:Taboo_tabs)
        let tabs = s:extract_tabs_from_str(get(g:, "Taboo_tabs", ""))
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
