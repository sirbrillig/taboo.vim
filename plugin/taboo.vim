" =============================================================================
" File: taboo.vim
" Description: A lightweight plugin for customizing tabs. 
" Mantainer: Giacomo Comitti <giacomit at gmail dot com>
" Last Changed: 16 Sep 2012
" Version: 0.0.1
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

if !exists("g:tab_before_chars")
    let g:tab_before_chars = ''
endif

if !exists("g:tab_after_chars")
    let g:tab_after_chars = ''
endif

if !exists("g:tab_renamed_before_chars")
    let g:tab_renamed_before_chars = '['
endif

if !exists("g:tab_renamed_after_chars")
    let g:tab_renamed_after_chars = ']'
endif

if !exists("g:tab_modified_flag")
    let g:tab_modified_flag = '*'
endif

" f -> only file name
" r -> relative to home
" a -> absolute path
if !exists("g:tab_type_path")
    let g:tab_type_path = 'f'
endif

if !exists("g:tab_display_close_label")
    let g:tab_display_close_label = 0
endif    

if !exists("g:tab_close_label")
    let g:tab_close_label = 'x '
endif    

if !exists("g:tab_unnamed")
    let g:tab_unnamed = '[no name]'
endif    

" }}}


" TabooTabline ------------------- {{{

function! TabooTabline()
    call s:RefreshTabsWithCustomLabel()
    let s = ''
    for i in range(1, tabpagenr('$'))
        " specific highlighting for the current tab
        let s .= i == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#'
                                                            
        let buflist = tabpagebuflist(i)
        let winnr = tabpagewinnr(i)
        let label = ""
        let label = get(s:taboo_tabs_labels, i)

        if label == "0" 
            " tab with no custom label

            let label = g:tab_before_chars           
            let label_ = bufname(buflist[winnr - 1])
            let file_name = fnamemodify(label_, ':p:t')
            let abs_path = fnamemodify(label_, ':p:h')
            if g:tab_type_path == "f"
                let label .= file_name
            elseif g:tab_type_path == "r"
                let label .= substitute(abs_path, $HOME, '', '')
                let label .= ("/" . file_name)
            elseif g:tab_type_path == "a"
                let label .= (abs_path . "/" . file_name)
            endif

            if label == g:tab_before_chars . g:tab_after_chars
                let label = g:tab_unnamed
            endif

            if getbufvar(buflist[winnr - 1], "&mod")
                let label .= g:tab_modified_flag
            endif

            let label .= g:tab_after_chars
        else
            " tab with custom label

            let buf_mod_in_tab = 0
            for b in buflist
                if getbufvar(b, "&mod")
                    let buf_mod_in_tab = 1
                endif
            endfor

            if buf_mod_in_tab
                let label .= g:tab_modified_flag
            endif
        endif

        let s .= ' ' . label . ' '
    endfor
    let s .= '%#TabLineFill#'

    " display he label for closing tabs
    if tabpagenr('$') > 1 && g:tab_display_close_label
        let s .= '%=%#TabLine#%999' . g:tab_close_label
    endif

    return s
endfunction

" }}}

" RenameTab ---------------------- {{{

fu! s:RenameTab(label)
    " strip from any space character before and after
    let label = substitute(a:label, '^\s*\(.\{-}\)\s*$', '\1', '')
    let tabnr = tabpagenr()        
    let _label = g:tab_renamed_before_chars . label . g:tab_renamed_after_chars
    let s:taboo_tabs_labels[tabnr] = _label
    " refresh the tabline
    set showtabline=1
endfu

" }}}

" RefreshTabsWithCustomLabel ----- {{{

function! s:RefreshTabsWithCustomLabel()
    if !g:tab_persistent_label
        for i in keys(s:taboo_tabs_labels)
            if i > tabpagenr('$')
                unlet s:taboo_tabs_labels[i]
            endif
        endfor
    endif
endfunction

" }}}

" RenameTabPrompt ---------------- {{{

function! s:RenameTabPrompt()
    let label = input("New tab label:")
    call s:RenameTab(label)
endfunction

" }}}

" ToggleLabelPersistence --------- {{{

function! s:ToggleLabelPersistence()
    let g:tab_persistent_label = !g:tab_persistent_label
endfunction

" }}}


command! -bang -nargs=1 TabooRename call s:RenameTab(<q-args>)
command! -bang -nargs=0 TabooRenamePrompt call s:RenameTabPrompt()
command! -bang -nargs=0 TabooTogglePersistence call s:ToggleLabelPersistence()

augroup taboo
    au TabLeave * call s:RefreshTabsWithCustomLabel() 
augroup END




