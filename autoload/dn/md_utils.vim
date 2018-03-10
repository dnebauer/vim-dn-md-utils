" Title:   autoload script for vim-dn-markdown ftplugin
" Author:  David Nebauer
" URL:     https://github.com/dnebauer/vim-dn-markdown

" Load only once    {{{1
if exists('g:loaded_dn_md_utils_autoload') | finish | endif
let g:loaded_dn_md_utils_autoload = 1

" Save coptions    {{{1
let s:save_cpo = &cpoptions
set cpoptions&vim

" Variables    {{{1
let s:metadata_triad = [
            \ 'title:  "[][source]"',
            \ 'author: "[][author]"',
            \ 'date:   ""'
            \ ]
let s:metadata_style = 'style:  [Standard, Latex12pt]  # panzer: '
            \ . '8-12,14,17,20pt; PaginateSections'
let s:refs = [
            \ '',
            \ '[comment]: # (URLs)',
            \ '',
            \ '   [author]: ',
            \ '',
            \ '   [source]: '
            \ ]

" Public functions    {{{1

" dn#md_utils#panzerifyMetadata([insert])    {{{2
" does:   convert yaml metadata block to use panzer
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#md_utils#panzerifyMetadata(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    let l:pos = getcurpos()
    try
        " must have yaml metadata block at beginning of file
        let l:first_line = getline(1)
        if l:first_line !~# '^---\s*$'
            throw 'Cannot find yaml metadata block at head of file'
        endif
        call cursor(1, 1)
        let l:end_metadata = search('^\(---\|\.\.\.\)\s*$', 'W')
        if !l:end_metadata
            throw 'Cannot find end of metadata block at head of file'
        endif
        let l:file_metadata = getline(2, l:end_metadata - 1)
        " keep initial comments and title, author and date fields
        let l:metadata = ['---']
        for l:line in l:file_metadata
            if l:line =~# '^#'  " keep comments
                call add(l:metadata, l:line)
                continue
            endif
            let l:match = matchlist(l:line, '\_^\(\a\%[\l-]\+\):')
            if empty(l:match)  " plain line, may be continuation, keep
                call add(l:metadata, l:line)
                continue
            endif
            " is a yaml field, terminate unless title|author|date
            let l:field = l:match[1]
            if l:field =~# '\_^\(title\|author\|date\)\_$'
                call add(l:metadata, l:line)
                continue
            endif
            break
        endfor
        " delete any comment lines at end of metadata
        while l:metadata[-1] =~# '^#'
            unlet l:metadata[-1]
        endwhile
        " add panzer style to end of metadata block
        let l:panzer_metadata = [s:metadata_style, '---']
        call extend(l:metadata, l:panzer_metadata)
        " delete current metadata
        execute '1,' . l:end_metadata . 'd'
        " insert new metadata
        call append(0, l:metadata)
    finally
        call setpos('.', l:pos)
        redraw!
    endtry
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#md_utils#addBoilerplate([insert])    {{{2
" does:   add panzer/markdown boilerplate to top and bottom of file
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#md_utils#addBoilerplate(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    let l:pos = getcurpos()
    try
        " add yaml metadata boilerplate at beginning of file
        let l:metadata = ['---']
        call extend(l:metadata, s:metadata_triad)
        call extend(l:metadata, [s:metadata_style, '---'])
        call append(0, l:metadata)
        " add references boilerplate to end of file
        call append(line('$'), s:refs)
        " reset cursor
        let l:pos[1] += len(l:metadata)
    finally
        call setpos('.', l:pos)
        redraw!
    endtry
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" Private functions    {{{1

" s:_utils_missing()    {{{2
" does:   determine whether dn-utils plugin is loaded
" params: nil
" prints: nil
" return: whether dn-utils plugin is loaded
function! s:_utils_missing() abort
    if exists('g:loaded_dn_utils')
        return g:dn_false
    else
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return g:dn_true
    endif
endfunction


" Restore cpoptions    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo    " }}}1

" vim: set foldmethod=marker :
