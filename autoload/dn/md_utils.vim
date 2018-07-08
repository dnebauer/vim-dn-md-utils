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

" dn#md_utils#insertFigure([insert])    {{{2
" does:   insert figure on new line
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#md_utils#insertFigure(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " insert figure
    call s:_insert_figure()
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

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

" dn#md_utils#cleanOutput([insert])    {{{2
" does:   delete output files and temporary directories
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#md_utils#cleanOutput(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " clean output files
    call s:_clean_output()
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" Private functions    {{{1

" s:_clean_output()    {{{2
" does:   deletes 'FILE.html' file, 'FILE.pdf' file and '.tmp' directory
" params: caller - where function was called from
"                  [no default, optional, string]
"         file - filename of current buffer
"                  [no default, optional, string]
" prints: feedback
" return: n/a
function! s:_clean_output(...) abort
    " get path components; involves params
    let l:fp = resolve(expand('%:p'))
    let l:confirm = g:dn_false
    let l:verbose = g:dn_true
    if a:0 > 0
        let l:valid_callers = ['au']
        let l:caller = a:1
        if !count(l:valid_callers, l:caller)
            call dn#util#error('Invalid caller: "' . l:caller . '"')
            return
        endif
        if l:caller ==# 'au'
            if a:2
                let l:fp = resolve(expand(a:2))
                let l:confirm = g:dn_true
                let l:verbose = g:dn_false
            else
                return g:dn_false  " exit without feedback
            endif
        else
            call dn#util#error('Unhandled caller: "' . l:caller . '"')
            return
        endif
    endif
    if empty(l:fp)
        if l:verbose
            call dn#util#error('Buffer is not a file!')
        endif
        return
    endif
    let l:dir = fnamemodify(l:fp, ':h')
    let l:file = fnamemodify(l:fp, ':t')
    let l:base = fnamemodify(l:file, ':r')
    " identify deletion candidates
    let l:deletable_suffixes = ['htm', 'html', 'pdf', 'epub', 'mobi']
    let l:deletable_subdirs = ['.tmp']
    let l:fps_for_deletion = []
    let l:dirs_for_deletion = []
    for l:suffix in l:deletable_suffixes
        let l:candidate = l:dir . '/' . l:base . '.' . l:suffix
        if filereadable(l:candidate)
            call add(l:fps_for_deletion, l:candidate)
        endif
    endfor
    for l:subdir in l:deletable_subdirs
        let l:candidate = l:dir . '/' . l:subdir
        if isdirectory(l:candidate)
            call add(l:dirs_for_deletion, l:candidate)
        endif
    endfor
    if empty(l:fps_for_deletion) && empty(l:dirs_for_deletion)
        if l:verbose
            echo 'No output to clean up'
        endif
        return
    endif
    " confirm deletion if necessary
    if l:confirm
        let l:for_deletion = l:fps_for_deletion + l:dirs_for_deletion
        echo 'Output files and/or dirs detected:'
        echo '- ' . join(l:for_deletion, ', ')
        echohl Question
        echo 'Delete them? [y/N] '
        echohl None
        let l:char = nr2char(getchar())
        echon l:char
        if l:char !=? 'y'
            echo 'Okay, no deletions'
            return
        endif
    endif
    " delete files/dirs
    let l:deleted = []
    let l:failed = []
    for l:fp in l:fps_for_deletion
        let l:result = delete(l:fp)
        if     l:result == 0  " success
            call add(l:deleted, fnamemodify(l:fp, ':t'))
        elseif l:result == -1  " (partial) failure
            call add(l:failed, l:fp)
        else
            " should not be possible
            call dn#util#error('Unable to delete ' . l:fp)
        endif
    endfor
    for l:dir in l:dirs_for_deletion
        let l:result = delete(l:dir, 'rf')  " delete recursively!!
        if     l:result == 0  " success
            call add(l:deleted, fnamemodify(l:dir, ':t'))
        elseif l:result == -1  " (partial) failure
            call add(l:failed, l:dir)
        else
            " should not be possible
            call dn#util#error('Unable to recursively force delete ' . l:dir)
        endif
    endfor
    " report outcome
    if !empty(l:deleted)
        echo 'Deleted ' . join(l:deleted, ', ')
    endif
    if !empty(l:failed)
        call dn#util#error('Errors occurred trying to delete:')
        for l:path in l:failed
            call dn#util#error('- ' . l:path)
        endfor
    endif
endfunction

" s:_insert_figure()    {{{2
" does:   insert figure
" params: nil
" prints: nil
" return: n/a
function! s:_insert_figure() abort
    " get image file
    let l:prompt = 'Enter image filepath (empty to abort): '
    let l:path = input(l:prompt, '', 'file')
    if empty(l:path) | return | endif
    if !filereadable(l:path)
        echo ' '  | " ensure move to a new line
        let l:prompt  = 'Image filepath appears to be invalid:'
        let l:options = []
        call add(l:options, {'Proceed anyway': g:dn_true})
        call add(l:options, {'Abort': g:dn_false})
        let l:proceed = dn#util#menuSelect(l:options, l:prompt)
        if !l:proceed | return | endif
    endif
    " get image caption
    let l:prompt = 'Enter image caption (empty to abort): '
    let l:caption = input(l:prompt)
    echo ' '  | " ensure move to a new line
    if empty(l:caption) | return | endif
    " get id/label
    let l:default = tolower(l:caption)
    let l:default = substitute(l:default, '[^a-z0-9_-]', '-', 'g')
    let l:default = substitute(l:default, '^-\+', '', '')
    let l:default = substitute(l:default, '-\+$', '', '')
    let l:default = substitute(l:default, '-\{2,\}', '-', 'g')
    let l:prompt  = 'Enter figure id (empty to abort): '
    while 1
        let l:id = input(l:prompt, l:default)
        echo ' '  | " ensure move to a new line
        " empty value means aborting
        if empty(l:id) | return '' | endif
        " must be legal id
        if l:id !~# '\%^[a-z0-9_-]\+\%$'
            call dn#util#warn('Ids contain only a-z, 0-9, _ and -')
            continue
        endif
        " ok, if here must be legal
        break
    endwhile
    " get (optional) attributes
    let l:attributes = []
    let l:name_default = 'width'
    let l:value_default = '50%'
    while 1
        " get attribute name
        let l:prompt = 'Enter attribute name (empty to abort): '
        let l:name = input(l:prompt, l:name_default)
        echo ' '  | " ensure move to a new line
        if empty(l:name) | break | endif  " finished entering attributes
        " get attribute value
        let l:prompt = 'Enter attribute value (empty to abort): '
        let l:value = input(l:prompt, l:value_default)
        echo ' '  | " ensure move to a new line
        if empty(l:value) | break | endif  " finished entering attributes
        " add attribute
        call add(l:attributes, l:name . '="' . l:value . '"')
        " only suggest for first attribute
        let l:name_default = ''
        let l:value_default = ''
    endwhile
    " assemble link and link definition
    let l:attrs_str = ''
    if !empty(l:attributes)
        let l:attrs_str = ' .class ' . join(l:attributes)
    endif
    let l:link = '![' . l:caption . '][' . l:id . ']'
    let l:defn = '   [' . l:id . ']: ' . l:path . ' ' . '"' . l:caption 
                \ . '" {#fig:' . l:id . l:attrs_str . '}'
    " insert link
    let l:lines = [l:link, '', '']  " link and two empty lines
    for l:line in reverse(l:lines)
        let l:failed = append(line('.'), l:line)
        if l:failed
            let l:msg = 'Error occurred while inserting figure link'
            call dn#util#error(l:msg)
            return
        endif
    endfor
    let l:pos = getcurpos()
    let l:pos[1] += len(l:lines)
    " insert link definition
    call cursor(line('$'), 0)
    let l:lines = ['', l:defn]
    for l:line in reverse(l:lines)  " link and two empty lines
        let l:failed = append(line('.'), l:line)
        if l:failed
            let l:msg = 'Error occurred while inserting link definition'
            call dn#util#error(l:msg)
            return
        endif
    endfor
    " reset cursor position
    call setpos('.', l:pos)
endfunction

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
