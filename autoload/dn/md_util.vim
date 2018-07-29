" Vim ftplugin for markdown
" Last change: 2018 Jul 28
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
" (https://github.com/msprev/panzer) for markdown support. This plugin is
" intended to address any gaps in markdown support provided by those tools.
"
" @subsection Dependencies
"
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
"
" This plugin also depends on the vim-dn-utils plugin
" (https://github.com/dnebauer/vim-dn-utils).

""
" @section Features, features
" The major features of this plugin are support for yaml metadata blocks,
" adding figures, and cleaning up output file and directories.
"
" @subsection Metadata
"
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
"
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
"
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
" names like "FILE.html" and "FILE.pdf" (see @function(dn#md_util#cleanBuffer)
" for a complete list). The temporary output subdirectory ".tmp" will also be
" recursively force deleted. Warning: This plugin does not check that it is
" safe to delete files and directories identified for deletion. For example,
" it does not check whether any of them are symlinks to other locations. Also
" be aware that directories are forcibly and recursively deleted, as with the
" *nix shell command "rm -fr".
"
" When a markdown buffer is closed (actually when the |BufDelete| event
" occurs), the plugin checks for output files/directories and, if any are
" found, asks the user whether to delete them. If the user confirms deletion
" they are removed. When vim exits (actually, when the |VimLeavePre| event
" occurs) the plugin looks for any markdown buffers and looks in their
" respective directories for output files/directories and, if any are found,
" asks the user whether to delete them. See @section(autocmds) for further
" details.
" 
" Output files and directories associated with the current buffer can be
" deleted at any time by using the @function(dn#md_util#cleanBuffer) function,
" which can be called using the command @command(MUCleanOutput) and mapping
" "<Leader>co" (see @section(mappings)).

""
" @setting b:disable_dn_md_utils
" Prevents this plugin loading if set to a true value before this plugin would
" normally load.

" }}}1

" Script variables

" s:clean_dirs     - temporary output directory names    {{{1

""
" Names of temporary directories created during pandoc output.
let s:clean_dirs = ['.tmp']

" s:clean_suffixes - suffixes of output files    {{{1

""
" Suffixes of output files that will be deleted by cleanup routine.
let s:clean_suffixes = ['htm', 'html', 'pdf', 'epub', 'mobi']

" s:md_filetypes   - valid markdown filetypes    {{{1

""
" List of valid markdown filetypes.
"
let s:md_filetypes = ['markdown', 'markdown.pandoc', 'pandoc']

" s:metadata_style - metadata skeleton for panzer styles    {{{1

""
" Metadata skeleton for panzer styles.
let s:metadata_style = [
            \ 'style:  [Standard, Latex14pt]',
            \ '        # Latex8-12|14|17|20pt; PaginateSections; InludeFiles'
            \ ]

" s:metadata_triad - metadata skeleton for title/author/date    {{{1

""
" Metadata skeleton for title, author and date.
let s:metadata_triad = [
            \ 'title:  "[][source]"',
            \ 'author: "[][author]"',
            \ 'date:   ""'
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

" }}}1

" Script functions

" s:clean_output(buffer_number, [confirm])    {{{1

""
" @private
" Deletes common output artefacts: output files with extensions like "html"
" and "pdf", and temporary directories like ".tmp". (See
" @function(dn#util#cleanOutput) for a complete list.)
"
" Obtains file path associated with the buffer identified by {buffer_number}.
" From this file path obtains the file directory and basename of output files.
" Function exits if there is no file associated with the buffer (because
" pandoc will not create output for it).
"
" See @function(a:valid_bufnr) for notes on how buffer number is checked.
"
" If [confirm] is true the user will be asked for confirmation before anything
" is deleted. (No confirmation is necessary if there is nothing to delete.)
" @default confirm=0
function! s:clean_output(bufnr, ...) abort
    " check params
    if !s:valid_bufnr(a:bufnr) | return | endif
    let l:confirm = (a:0 && a:1)
    " identify deletion candidates
    let l:filepath = simplify(resolve(fnamemodify(bufname(a:bufnr), ':p')))
    let [l:fps, l:dirs] = s:output_artefacts(l:filepath)
    if empty(l:fps) && empty(l:dirs)
        echo 'No output to clean up'
        return
    endif
    " confirm deletion if necessary
    if l:confirm
        let l:artefacts = join(map(l:fps, function('s:filename'))
                    \   + map(l:dirs, function('s:filename')), ', ')
        "echo 'Dir: ' . fnamemodify(l:filepath, ':h')
        "echo 'Output artefacts: ' . l:artefacts
        let l:msg = ['Dir: ' . fnamemodify(l:filepath, ':h'),
                    \ 'Output artefacts: ' . l:artefacts]
        if !s:confirm('Delete output? [y/N] ', l:msg) | return | endif
    endif
    " delete files/dirs
    let [l:deleted, l:failed] = s:delete_output(l:fps, l:dirs)
    " report outcome
    call s:report_clean(l:deleted, l:failed)
endfunction

" s:confirm(question, [preamble])    {{{1

""
" @private
" Asks user a {question} to be answered with a 'y' or 'n'. May be preceded by
" a [preamble], a list of strings displayed before the question.
" @default preamble=[]
function! s:confirm(question, ...) abort
    let l:preamble = (a:0 && !empty(a:1)) ? a:1 : []
    echohl MoreMsg
    for l:msg in l:preamble | echo l:msg | endfor
    echohl None
    echohl Question
    echo a:question
    echohl None
    let l:char = nr2char(getchar())
    echon l:char
    return (l:char ==? 'y')
endfunction

" s:delete_output(filepaths, directories)    {{{1

""
" @private
" Attempts to delete {filepaths} and {directories}. Returns a list of
" successfully deleted files and directories, and a list of items that could
" not be deleted.
"
" Note in this function that the return value from |delete()| is not boolean;
" it returns 0 if successful and -1 if the deletion fails or partly fails.
function! s:delete_output(fps, dirs) abort
    let l:deleted = [] | let l:failed = []
    for l:fp in a:fps
        let l:result = delete(l:fp)
        if     l:result == 0  | call add(l:deleted, fnamemodify(l:fp, ':t'))
        elseif l:result == -1 | call add(l:failed, l:fp)
        else | call dn#util#error('Unable to delete ' . l:fp)
        endif
    endfor
    for l:dir in a:dirs
        let l:result = delete(l:dir, 'rf')  " delete recursively!!
        if     l:result == 0  | call add(l:deleted, fnamemodify(l:dir, ':t'))
        elseif l:result == -1 | call add(l:failed, l:dir)
        else | call dn#util#error('Unable to force delete ' . l:dir)
        endif
    endfor
    " return outcome
    return [l:deleted, l:failed]
endfunction

" s:filename(key, val)    {{{1

""
" @private
" A |Funcref| intended to be used with a |map()| function to extract a list if
" filenames from a list of filepaths. Uses the standard |Funcref| arguments
" {key} and {val}.
function! s:filename(key, val)
    return fnamemodify(a:val, ':t')
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

" s:md_filetype(filetype)    {{{1

""
" @private
" Determine whether {filetype} is a valid markdown filetype.
function! s:md_filetype(filetype)
    if empty(a:filetype) | return | endif
    return count(s:md_filetypes, a:filetype)
endfunction

" s:output_artefacts(filepath)    {{{1

""
" @private
" Finds common output artefacts, i.e., output files with extensions like
" "html" and "pdf", and temporary directories like ".tmp". (See
" @function(dn#util#cleanBuffer) for a complete list.) Uses directory and base
" name from {filepath}.
function! s:output_artefacts(filepath) abort
    let l:filepath = simplify(fnamemodify(a:filepath, ':p'))
    let l:dir = fnamemodify(l:filepath, ':h')
    let l:file = fnamemodify(l:filepath, ':t')
    let l:base = fnamemodify(l:file, ':r')
    " identify deletion candidates
    let l:fps = [] | let l:dirs = []
    for l:suffix in s:clean_suffixes
        let l:candidate = l:dir . '/' . l:base . '.' . l:suffix
        if filereadable(l:candidate) | call add(l:fps, l:candidate) | endif
    endfor
    for l:subdir in s:clean_dirs
        let l:candidate = l:dir . '/' . l:subdir
        if isdirectory(l:candidate) | call add(l:dirs, l:candidate) | endif
    endfor
    return [l:fps, l:dirs]
endfunction

" s:report_clean(deleted, failed)    {{{1

""
" @private
" Report on outcome of output cleaning. The report is based on a list of
" [deleted] files and directories, and a list of files and directories that
" [failed] to be deleted.
function! s:report_clean(deleted, failed) abort
    if !empty(a:deleted)
        echo 'Deleted ' . join(a:deleted, ', ')
    endif
    if !empty(a:failed)
        call dn#util#error('Errors occurred trying to delete:')
        for l:path in a:failed
            call dn#util#error('- ' . l:path)
        endfor
    endif
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

" s:valid_bufnr(buffer_number)    {{{1

""
" @private
" Checks that a buffer number is valid.
"
" Note that some buffers can exist but not be visible with the |:ls| command.
" For that reason this function checks that the supplied buffer number both
" exists and is associated with a file. For the purposes of this plugin a
" buffer number is invalid if it is not associated with a file name. This
" aligns with the behaviour of pandoc since it will not generate output if a
" buffer is not associated with a file. This also means an error will be
" generated for the edge case where a user has created a buffer and set a
" markdown filetype, but not saved the buffer as a file.
"
" For the purposes of this plugin a buffer is also invalid if it does not have
" a markdown filetype.
function! s:valid_bufnr(bufnr) abort
    " check params
    if type(a:bufnr) != type(0)  " check bufnr data type
        let l:msg = 'Expected buffer number, got '
                    \ . s:variable_type(a:bufnr) . ': ' . a:bufnr
        call dn#util#error(l:msg)
        return
    endif
    if !bufexists(a:bufnr)  " check bufnr exists
        call dn#util#error('Buffer ' . a:bufnr . ' does not exist')
        return
    endif
    if empty(bufname(a:bufnr))  " check buffer associated with a file
        call dn#util#error('No file associated with buffer ' . a:bufnr)
        return
    endif
    let l:ft = getbufvar(a:bufnr, '&filetype')  " check buffer file type
    if !s:md_filetype(l:ft)
        let l:msg = 'Buffer ' . a:bufnr . ' has non-md filetype: ' . l:ft
        call dn#util#error(l:msg)
        return
    endif
    " valid if survived tests
    return 1
endfunction

" s:variable_type(variable)    {{{1

""
" @private
" Returns the {variable} type as a string: "number", "string", "funcref",
" "List", "Dictionary", "float", or "unknown".
function! s:variable_type(var) abort
    if     type(a:var) == type(0)              | return 'number'
    elseif type(a:var) == type('')             | return 'string'
    elseif type(a:var) == type(function('tr')) | return 'funcref'
    elseif type(a:var) == type([])             | return 'List'
    elseif type(a:var) == type({})             | return 'Dictionary'
    elseif type(a:var) == type(0.0)            | return 'float'
    else                                       | return 'unknown'
    endif
endfunction
" }}}1

" Private functions

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

" dn#md_util#cleanAllBuffers([insert])    {{{1

""
" @public
" Deletes common output artefacts: output files with extensions like "html"
" and "pdf", and temporary directories like ".tmp". (See
" @function(dn#util#cleanBuffer) for a complete list.)
"
" Searches sequentially through all buffers that are both associated with a
" file name and have a markdown file type. When output artefacts are located
" the user is asked for confirmation before deletion.
"
" The [insert] argument has a boolean value which determines whether or not
" the function was entered from insert mode.
" @default insert=0
function! dn#md_util#cleanAllBuffers(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:utils_missing() | return | endif  " requires dn-utils plugin
    " process params
    let l:insert = (a:0 && a:1)
    " cycle through buffers, acting only on those with markdown files
    for l:bufnr in range(1, bufnr('$'))
        if !bufexists(l:bufnr) | continue | endif
        if empty(bufname(l:bufnr)) | continue | endif
        if !s:md_filetype(getbufvar(l:bufnr, '&filetype')) | continue | endif
        call s:clean_output(l:bufnr, 1)
    endfor
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#md_util#cleanBuffer(buffer_number[, confirm[, insert]])    {{{1

""
" @public
" Deletes common output artefacts: output files with extensions "htm", "html",
" "pdf", "epub", and "mobi"; and temporary directories names ".tmp".
"
" Searches for output located in the file directory associated with buffer
" {buffer_number}.
"
" If [confirm] is true, the user will be asked for confirmation before
" deleting output artefacts. (If there are no artefacts the user is not asked
" for confirmation.)
" @default confirm=0
"
" The [insert] argument has a boolean value which determines whether or not
" the function was entered from insert mode.
" @default insert=0
function! dn#md_util#cleanBuffer(bufnr, ...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:confirm = (a:0 > 0 && a:1)
    let l:insert = (a:0 > 1 && a:2)
    " clean output files
    call s:clean_output(a:bufnr, l:confirm)
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

" vim: set foldmethod=marker :
