" Vim ftplugin for markdown
" Last change: 2018 Jul 26
" Maintainer: David Nebauer
" License: CC0

" Documentation {{{1

""
" @section Introduction, intro
" @order intro features settings commands mappings vars autocmds
" An auxiliary filetype plugin for the markdown language.
"
" Previously the plugin author used a personal plugin to provide markdown-
" related functionality. That plugin was retired when the plugin author
" switched to the |vim-pandoc| plugin and panzer framework
" (https://github.com/msprev/panzer) for markdown support.
"
" This plugin is intended to address any gaps in markdown support provided by
" those tools. It currently provides support for a pandoc-compliant
" yaml-metadata block at the top of a document (with links collected at the
" bottom of a document) using panzer styles.
"
" @subsection Dependencies
" Pandoc is used to generate output. It is not provided by this ftplugin.
" This ftplugin depends on the |vim-pandoc| plugin and assumes panzer
" (https://github.com/msprev/panzer) is installed and configured.
"
" This plugin is designed for use with pandoc version 2.0. At the time of
" writing this is the development branch of pandoc, while the production
" version is 1.19. As the change in major version number suggests, the
" interfaces of these two versions of pandoc are incompatible. Hence, this
" plugin will not work with the current production version of pandoc. There
" are two known incompatibilities between these versions that affect this
" plugin. The first is that the "smart" feature has changed from an option
" ("--smart") to an extension ("--from=markdown+smart"). The second is a
" change in the option used to specify the latex engine from "--latex-engine"
" to "--pdf-engine".

""
" @section Features, features
" The major features of this plugin are support for yaml metadata blocks,
" adding figures, and cleaning up output file and directories.
"
" @subsection Metadata
" Pandoc-flavoured markdown uses a yaml-style metadata block at the top of the
" file to specify values used by pandoc for document processing. With panzer
" (https://github.com/msprev/panzer) installed the metadata block can also
" specify panzer-related values which, in turn, specify values used by pandoc
" for document processing.
"
" This ftplugin assumes the following default yaml-metadata block is used at
" the top of documents:
" >
"     ---
"     title:  "[][source]"
"     author: "[][author]"
"     date:   ""
"     style:  [Standard, Latex12pt]  # panzer: 8-12,14,17,20pt; PaginateSections
"     ---
" <
" The reference-style links are defined at the end of the document. The
" default boilerplate for this is:
" >
"     [comment]: # (URLs)
"     
"        [author]: 
"     
"        [source]: 
" <
" The default metadata block and reference link definitions are added to a
" document by the function @function(dn#md_util#addBoilerplate), which can be
" called using the command @command(MUAddBoilerplate) and mapping "<Leader>ab"
" (see @section(mappings)).
"
" Previously created markdown files have yaml metadata blocks that do not use
" panzer. Those metadata blocks can be "panzerified" using the
" @function(dn#md_util#panzerifyMetadata) function, which can be called using
" the command @command(MUPanzerifyMetadata) and mapping "<Leader>pm" (see
" @section(mappings)).
"
" @subsection Images
" A helper function, mapping and command are provided to assist with adding
" figures. They assume the images are defined using reference links with
" optional attributes, and that all reference links are added to the end of
" the document prefixed with three spaces. For example:
" >
"     See @fig:display and {@fig:packed}.
" 
"     ![Tuck boxes displayed][display]
" 
"     ![Tuck boxes packed away][packed]
" 
"     [comment]: # (URLs)
" 
"        [display]: resources/displayed.png "Tuck boxes displayed"
"        {#fig:display .class width="50%"}
" 
"        [packed]: resources/packed.png "Tuck boxes packed away"
"        {#fig:packed .class width="50%"} 
" <
" A figure is inserted on the following line using the
" @function(dn#md_util#insertFigure) function, which can be called using the
" command @command(MUInsertFigure) and mapping "<Leader>fig" (see
" @section(mappings)).
"
" @subsection Output
" This plugin does not assist with generation of output, but does provide a
" mapping, command and function for deleting output files and temporary output
" directories. The term "clean" is used, as in the makefile keyword that
" deletes all working and output files.
"
" Cleaning of output only occurs if the current buffer contains a file. The
" directory searched for items to delete is the directory in which the file in
" the current buffer is located.
"
" If the file being edited is FILE.ext, the files that will be deleted have
" names like "FILE.html" and "FILE.pdf" (see
" @function(dn#md_util#cleanOutput) for a complete list). The temporary
" output subdirectory ".tmp" will also be recursively force deleted. Warning:
" This plugin does not check that it is safe to delete files and directories
" identified for deletion. For example, it does not check whether any of them
" are symlinks to other locations. Also be aware that directories are forcibly
" and recursively deleted, as with the *nix shell command "rm -fr".
"
" When a markdown buffer is closed (actually when the |BufDelete| event
" occurs), the plugin checks for output files/directories and, if any are
" found, asks the user whether to delete them. If the user confirms deletion
" they are removed. When vim exits (actually, when the |VimLeavePre| event
" occurs) the plugin looks for any markdown buffers and looks in their
" respective directories for output files/directories and, if any are found,
" asks the user whether to delete them.
" 
" Output files and directories can be deleted at any time by using the
" @function(dn#md_util#cleanOutput) function, which can be called using the
" command @command(MUCleanOutput) and mapping "<Leader>co" (see
" @section(mappings)).

""
" @setting b:disable_dn_md_utils
" Disables this plugin if set to a true value.

" }}}1

" Script variables

" s:metadata_triad - metadata skeleton for title/author/date    {{{1

""
" Metadata skeleton for title, author and date.
let s:metadata_triad = [
            \ 'title:  "[][source]"',
            \ 'author: "[][author]"',
            \ 'date:   ""'
            \ ]

" s:metadata_style - metadata skeleton for panzer styles    {{{1

""
" Metadata skeleton for panzer styles.
let s:metadata_style = [
            \ 'style:  [Standard, Latex14pt]',
            \ '        # Latex8-12|14|17|20pt; PaginateSections; InludeFiles'
            \ ]

" s:refs           - skeleton for url comment block    {{{1

""
" Comment block for url references to go at end of document.
let s:refs = [
            \ '',
            \ '[comment]: # (URLs)',
            \ '',
            \ '   [author]: ',
            \ '',
            \ '   [source]: '
            \ ]

" s:clean_suffixes - suffixes of output files    {{{1

""
" Suffixes of output files that will be deleted by cleanup routine.
let s:clean_suffixes = ['htm', 'html', 'pdf', 'epub', 'mobi']

" s:clean_dirs     - temporary output directory names    {{{1

""
" Names of temporary directories created during pandoc output.
let s:clean_dirs = ['.tmp']

" s:register       - details of markdown buffers    {{{1

""
" Details of markdown buffers. Has the structure:
" [
"   {
"     'filepath': FILEPATH,
"      'bufname': BUFFER_NAME,
"        'bufnr': BUFFER_NUMBER,
"     'filetype': FILETYPE},
"   ...
" ]
" BUFFER_NAME and BUFFER_NUMBER are the values reported by |bufname()| and
" |bufnr()|, respectively. BUFFER_NAME may differ from FILEPATH since the
" latter has been processed by the |simplify()|, |resolve()| and |expand()|
" functions.
let s:register = []
" }}}1

" Script functions

" s:clean_output([caller[, caller_arg]])    {{{1

""
" @private
" Deletes common output artefacts: output files with extensions "htm", "html",
" "pdf", "epub", and "mobi"; and temporary directories names ".tmp".
"
" The [caller] argument provides the calling context. This can be one of
" "mapping", "command" or "autocmd". An argument can be provided for the
" caller: this is the [caller_arg]. The [caller] "autocmd" expects a file path
" [caller_arg]. The [caller] arguments "mapping" and "command" ignore any
" accompanying [caller_arg].
"
" @default caller=""
" @default caller_arg=""
function! s:clean_output(...) abort
    " get path components; involves params
    let l:fp = resolve(expand('%:p'))
    let l:on_buf_close = g:dn_false
    let l:verbose = g:dn_true
    if a:0 > 0
        " process caller (first param)
        let l:valid_callers = ['mapping', 'command', 'autocmd']
        let l:caller = a:1
        if !count(l:valid_callers, l:caller)
            call dn#util#error('Invalid caller: "' . l:caller . '"')
            return
        endif
        " process caller arg (second param) depending on caller
        " - note that 'mapping' and 'command' callers ignore arg,
        "   and also have no effect whatsoever
        if l:caller ==# 'autocmd'
            if !empty(a:2)
                let l:fp = simplify(resolve(expand(a:2)))
                let l:on_buf_close = g:dn_true
                let l:verbose = g:dn_false
            endif
        endif
    endif
    if empty(l:fp)
        if l:verbose | call dn#util#error('Buffer is not a file!') | endif
        return
    endif
    let l:dir = fnamemodify(l:fp, ':h')
    let l:file = fnamemodify(l:fp, ':t')
    let l:base = fnamemodify(l:file, ':r')
    " identify deletion candidates
    let l:fps_for_deletion = []
    let l:dirs_for_deletion = []
    for l:suffix in s:clean_suffixes
        let l:candidate = l:dir . '/' . l:base . '.' . l:suffix
        if filereadable(l:candidate)
            call add(l:fps_for_deletion, l:candidate)
        endif
    endfor
    for l:subdir in s:clean_dirs
        let l:candidate = l:dir . '/' . l:subdir
        if isdirectory(l:candidate)
            call add(l:dirs_for_deletion, l:candidate)
        endif
    endfor
    if empty(l:fps_for_deletion) && empty(l:dirs_for_deletion)
        if l:verbose | echo 'No output to clean up' | endif
        return
    endif
    " confirm deletion if necessary
    if l:on_buf_close
        let l:to_delete = l:fps_for_deletion + l:dirs_for_deletion
        echo 'Output files and/or dirs detected: ' . join(l:to_delete, ', ')
        echohl Question
        echo 'Delete them? [y/N] '
        echohl None
        let l:char = nr2char(getchar())
        echon l:char
        if l:char !=? 'y' | return | endif
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
    if !empty(l:deleted) && !l:on_buf_close
        echo 'Deleted ' . join(l:deleted, ', ')
    endif
    if !empty(l:failed)
        call dn#util#error('Errors occurred trying to delete:')
        for l:path in l:failed
            call dn#util#error('- ' . l:path)
        endfor
    endif
endfunction

" s:insert_figure()    {{{1

""
" @private
" Insert figure.
function! s:insert_figure() abort
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

" s:utils_missing()    {{{1

""
" @private
" Determines whether dn-utils plugin is loaded.
function! s:utils_missing() abort
    if exists('g:loaded_dn_utils')
        return g:dn_false
    else
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return g:dn_true
    endif
endfunction
" }}}1

" Private functions

" dn#md_util#_register(filepath, filetype)    {{{1

""
" @private
" Registers the {filepath} of the buffer file if the {filetype} is markdown.
" Note there are dialects of markdown and the filetype value of a markdown
" file may simply be "markdown" or may be something like "markdown.pandoc".
function! dn#md_util#_register(fp, ft)
    if empty(a:fp) | return | endif  " not a file buffer
    if a:ft =~# '^markdown'  " is a markdown buffer
        let l:registered = 0
        for l:item in s:register
            if l:item['filepath'] ==# a:fp | let l:registered = 1 | endif
        endfor
        if !l:registered
            let l:new_item = {'filetype': a:fp,
                        \     'bufname' : bufname('%'),
                        \     'bufnr'   : bufnr('%'),
                        \     'filetype': a:ft}
            call add(s:register, l:new_item)
        endif
    else  " not a markdown buffer
        " must handle edge case where markdown buffer changed to another
        " filetype:
        " - use blunt force approach of checking entire register
        " - if register entry no longer matches any buffer, remove and clean
        let l:no_buffer_found = []
        " find registered bufnames with no corresponding buffers
        for l:item in s:register
            let l:bufname = l:item['bufname']
            if !bufexists(l:bufname)
                call add(l:no_buffer_found, l:bufname)
            endif
        endfor
        " for each orphaned bufname, delete register entry and clean up dir
        for l:bufname in l:no_buffer_found
            let l:index = 0
            while l:index < len(s:register)
                if s:register[l:index]['bufname'] ==# l:bufname
                    " TODO: add function call to check output
                    call remove(s:register, l:index)
                else
                    let l:index += 1
                endif
            endwhile
        endfor
    endif
endfunction

function! dn#md_util#_show_register()
    echo s:register
endfunction

" Public functions

" dn#md_util#addBoilerplate([insert])    {{{1

""
" @public
" Adds panzer/markdown boilerplate to the top and bottom of the document.
"
" The [insert] boolean argument determines whether or not the function was
" entered from insert mode.
" @default insert=false
function! dn#md_util#addBoilerplate(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    let l:pos = getcurpos()
    try
        " add yaml metadata boilerplate at beginning of file
        let l:metadata = ['---']
        call extend(l:metadata, s:metadata_triad)
        call extend(l:metadata, s:metadata_style)
        call add(l:metadata, '---')
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

" dn#md_util#insertFigure([insert])    {{{1

""
" @public
" Inserts a figure on a new line.
"
" The [insert] boolean argument determines whether or not the function was
" entered from insert mode.
" @default insert=false
function! dn#md_util#insertFigure(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " insert figure
    call s:insert_figure()
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#md_util#panzerifyMetadata([insert])    {{{1

""
" @public
" Adds a line to the initial metadata block, if present, for panzer styles.
" Intended for use when converting from plain pandoc to pandoc-plus-panzer.
"
" The [insert] boolean argument determines whether or not the function was
" entered from insert mode.
" @default insert=false
function! dn#md_util#panzerifyMetadata(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:utils_missing() | return | endif  " requires dn-utils plugin
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
        let l:panzer_metadata = s:metadata_style[:]  " copy
        call add(l:panzer_metadata, '---')
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

" dn#md_util#cleanOutput([args])    {{{1

""
" @public
" Deletes common output artefacts: output files with extensions "htm", "html",
" "pdf", "epub", and "mobi"; and temporary directories names ".tmp".
"
" Arguments are provided in optional |Dictionary| [args]. There are three
" valid keys for this dictionary: "insert", "caller" and "caller_arg".
"
" The "insert" key has a boolean value which determines whether or not the
" function was entered from insert mode.
"
" The "caller" key value provides the calling context. This can be one of
" "mapping", "command" or "autocmd". An argument can be provided for the
" caller: this is the value for the "caller_arg" key. The caller "autocmd"
" expects a file path "caller_arg". The caller arguments "mapping" and
" "command" ignore any accompanying "caller_arg".
"
" @default args={'insert': 0, 'caller': '', 'caller_arg': ''}
function! dn#md_util#cleanOutput(...) abort
    " may be called by autocmd with universal pattern
    if &filetype !~# '^markdown' | return | endif
    " universal tasks
    echo '' |  " clear command line
    if s:utils_missing() | return | endif  " requires dn-utils plugin
    let l:fn = 'dn#md_util#cleanOutput'
    " params
    let l:insert = g:dn_false
    let l:caller = ''
    let l:caller_arg = ''
    if a:0 > 1
        call dn#util#error(l:fn . ': expected 1 arg, got ' . a:0)
        return
    endif
    if a:0 == 1
        if type(a:1) != v:t_dict
            let l:type = dn#util#varType(a:1)
            call dn#util#error(l:fn . ': expected dict param, got ' . l:type)
            return
        endif
        let l:params = copy(a:1)
        for l:param in keys(l:params)
            let l:value = l:params[l:param]
            if     l:param ==# 'insert'     | let l:insert = g:dn_true
            elseif l:param ==# 'caller'     | let l:caller = l:value
            elseif l:param ==# 'caller_arg' | let l:caller_arg = l:value
            else
                call dn#util#error(
                            \ l:fn . ': invalid param key "' . l:param . '"')
                return
            endif
        endfor
    endif
    " clean output files
    call s:clean_output(l:caller, l:caller_arg)
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" vim: set foldmethod=marker :
