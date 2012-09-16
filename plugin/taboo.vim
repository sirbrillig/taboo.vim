" =============================================================================
" File: taboo.vim
" Description: A little plugin for customizing and renaming tabs. 
" Mantainer: Giacomo Comitti <giacomit at gmail dot com>
" Last Changed: 16 Sep 2012
" Version: 0.0.2
" =============================================================================

" Init --------------------------- {{{

if exists("g:loaded_taboo") || &cp
    finish
endif
let g:loaded_taboo = 1

" }}}

" Initialize variables ----------- {{{

if !exists("s:taboo_tabs_labels")
    let s:taboo_tabs_labels = {}
endif

" }}}

" Initialize default settings ---- {{{

" if the flag g:tab_persistent_label is set to true, a specific label remain
" attached to a specific tab number.
if !exists("g:tab_persistent_label")
    let g:tab_persistent_label = 0
endif

" n -> do not display numbers
" c -> display only current tab number
" a -> always display tab number
if !exists("g:tab_display_tabnr")
    let g:tab_display_tabnr = 'n'
endif

if !exists("g:tab_tabnr_separator")
    let g:tab_tabnr_separator = ' '
endif

if !exists("g:tab_before_str")
    let g:tab_before_str = '['
endif

if !exists("g:tab_after_str")
    let g:tab_after_str = ']'
endif

if !exists("g:tab_modified_flag")
    let g:tab_modified_flag = '*'
endif

" f -> only file name
" r -> relative to home
" a -> absolute path
if !exists("g:tab_type_path")
    let g:tab_type_path = 'r'
endif

if !exists("g:tab_display_close_label")
    let g:tab_display_close_label = 0
endif    

if !exists("g:tab_close_label")
    let g:tab_close_label = 'x '
endif    

if !exists("g:tab_unnamed_label")
    let g:tab_unnamed_label = '[no name]'
endif    

" }}}


" TabooTabline ------------------- {{{
" This function will be called only from the terminal

function! TabooTabline()
    call s:updateRenamedTabs()
    let s = ''
    for i in range(1, tabpagenr('$'))

        let active_tabnr = tabpagenr()        
        let buflist = tabpagebuflist(i)
        let winnr = tabpagewinnr(i)

        " specific highlighting for the current tab
        let s .= i == active_tabnr ? '%#TabLineSel#' : '%#TabLine#'
        let label = ""

        " display tab number
        if g:tab_display_tabnr == 'c'
            if i == active_tabnr
                let label .= i . g:tab_tabnr_separator
            endif
        elseif g:tab_display_tabnr == 'a'
            let label .= i . g:tab_tabnr_separator
        endif

        " display tab name
        let name = get(s:taboo_tabs_labels, i)
        if name == "0" 
            " tab with no custom name

            let path = bufname(buflist[0])
            let file_path = fnamemodify(path, ':p:t')
            let abs_path = fnamemodify(path, ':p:h')

            if g:tab_type_path == "f"
                let path = file_path
            elseif g:tab_type_path == "r"
                let path = substitute(abs_path . '/', $HOME, '', '')
                let path = "~" . path . file_path
            elseif g:tab_type_path == "a"
                let path = abs_path . "/" . file_path
            endif

            if empty(path)
                , let label .= g:tab_unnamed_label
                continue
            else                     
                let label .= path
            endif
        else
            let label .= join([g:tab_before_str, name, g:tab_after_str], '')
        endif

        " display modified flag
        " add the modified flag if there is some modified buffer into the tab. 
        " Note that this behaviour is different from the whom used by vim.
        " Infact by default vim display the modified flag for the buffer
        " shown in the label
        let buf_mod = 0
        for b in buflist
            if getbufvar(b, "&mod")
                let buf_mod = 1
            endif
        endfor
        let label .= buf_mod ? g:tab_modified_flag : ''

        let s .= ' ' . label . ' '
    endfor
    let s .= '%#TabLineFill#'

    " display he label for closing tabs
    if tabpagenr('$') > 1 && g:tab_display_close_label
        let s .= '%=%#TabLine#%999X' . g:tab_close_label
    endif

    return s
endfunction

" }}}

" RenameTab ---------------------- {{{

function! s:RenameTab(label)
    let tabnr = tabpagenr()        
    let s:taboo_tabs_labels[tabnr] = s:strip(a:label)
    " refresh the tabline FIX: I have to find a better solution
    set showtabline=1
endfunction

" }}}

" RenameTabPrompt ---------------- {{{

function! s:RenameTabPrompt()
    let label = input("New tab label: ")
    call s:RenameTab(label)
endfunction

" }}}

" updateRenamedTabs -------------- {{{

function! s:updateRenamedTabs()
    if !g:tab_persistent_label
        for i in keys(s:taboo_tabs_labels)
            if i > tabpagenr('$')
                " the tab # i does not exist anymore: remove it
                unlet s:taboo_tabs_labels[i]
            endif
        endfor
    endif
endfunction

" }}}

" ResetTabName -------------- {{{

function! s:ResetTabName()
    unlet s:taboo_tabs_labels[tabpagenr()]    
    set showtabline=1 " FIX: i have to find a better solution
endfunction

" }}}

 " ToggleLabelPersistence --------- {{{

function! s:ToggleLabelPersistence()
    let g:tab_persistent_label = !g:tab_persistent_label
endfunction

" }}}    

" strip -------------------------- {{{

function! s:strip(str)
    return substitute(a:str, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

" }}}


command! -bang -nargs=1 TabooRename call s:RenameTab(<q-args>)
command! -bang -nargs=0 TabooRenamePrompt call s:RenameTabPrompt()
command! -bang -nargs=0 TabooReset call s:ResetTabName()
command! -bang -nargs=0 TabooTogglePersistence call s:ToggleLabelPersistence()

augroup taboo
    au TabLeave * call s:updateRenamedTabs() 
augroup END




