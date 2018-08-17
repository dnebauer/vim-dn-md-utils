" Vim ftplugin for markdown
" Last change: 2018 Jul 28
" Maintainer: David Nebauer
" License: CC0

" Control statements    {{{1
set encoding=utf-8
scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" Documentation {{{1

""
" @section Introduction, intro
" @order intro features commands mappings autocmds functions help
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
"     style:  [Standard, Latex14pt]
"             # Latex8-12|14|17|20pt; PaginateSections; IncludeFiles
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
" document by the function @function(dn#md#addBoilerplate), which can be
" called using the command @command(MUAddBoilerplate) and mapping "<Leader>ab"
" (see @section(mappings)).
"
" Previously created markdown files have yaml metadata blocks that do not use
" panzer. Those metadata blocks can be "panzerified" using the
" @function(dn#md#panzerifyMetadata) function, which can be called using
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
" @function(dn#md#insertFigure) function, which can be called using the
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
" names like "FILE.html" and "FILE.pdf" (see @function(dn#md#cleanBuffer)
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
" deleted at any time by using the @function(dn#md#cleanBuffer) function,
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

" s:clean_output([arg])    {{{1

" - in block below @default must be a single line to be processed correctly by
"   vimdoc, so take care when formatting, e.g., with |gq|

""
" @private
" Deletes common output artefacts: output files with extensions like "html"
" and "pdf", and temporary directories like ".tmp". (See
" @function(dn#util#cleanOutput) for a complete list.)
"
" Returns boolean indicating whether any output was deleted.
"
" Obtains file path associated with the provided buffer number. This file path
" is used to obtain the file directory and basename of output files. The
" function exits if there is no file associated with the buffer (because
" pandoc will not create output for it).
"
" See @function(a:valid_bufnr) for notes on how the buffer number is checked.
"
" Optional [arg] is a |Dictionary| with a number of valid keys, all of which
" are themselves optional:
"
" key "bufnr" (number)
" * buffer number to process for output
"
" key "confirm" (bool)
" * whether, if output artefacts are detected, to ask user for confirmation
"   before anything is deleted
" 
" key "pause_end" (bool)
" * whether to pause after action taken; will not pause if no actions taken
"   and no feedback provided
"
" key "say_none" (bool)
" * whether to display a message if no output artefacts are detected
" 
" @default arg={'bufnr': 0, 'confirm': false, 'pause_end': false, 'say_none': false}
"
" @throws DelFail if fail to delete output files/directories
" @throws InvalidKey if Dict arg contains an invalid key
" @throws NoBuffer if no buffer has specified buffer number
" @throws NoFile if specified buffer has no associated file
" @throws NonBoolVal if non-boolean value assigned to boolean key
" @throws NonDictArg if expected Dict arg and got non-Dict
" @throws NonMDBuffer if specified buffer does not have a markdown filetype
" @throws WrongBufNrType if buffer number value is not a number
function! s:clean_output(...) abort
    " check params
    if a:0 > 1
        throw 'ERROR(ArgCount): Expected 1 arg, got ' . a:0
    endif
    try    | let l:arg = s:complete_arg(a:0 ? a:1 : {})
    catch  | throw s:exception_error(v:exception)
    endtry
    try    | call s:valid_bufnr(l:arg.bufnr)
    catch  | throw s:exception_error(v:exception)
    endtry
    " identify deletion candidates
    let l:md_fp = simplify(resolve(fnamemodify(bufname(l:arg.bufnr), ':p')))
    let [l:fps, l:dirs] = s:output_artefacts(l:md_fp)
    call s:log([fnamemodify(l:md_fp, ':t')] + l:fps + l:dirs) " DELETE LINE!
    if empty(l:fps) && empty(l:dirs)
        if l:arg.say_none | echomsg 'No output to clean up' | endif
        return
    endif
    " confirm deletion if necessary
    if l:arg.confirm
        let l:output = join(map(l:fps + l:dirs, function('s:rm_dir')), ', ')
        let l:fname = fnamemodify(l:md_fp, ':t')
        let l:msg = 'Delete ' . l:fname . ' output (' . l:output . ') [y/N] '
        if !s:confirm(l:msg) | return | endif
    endif
    " delete files/dirs
    let [l:deleted, l:failed] = s:delete_output(l:fps, l:dirs)
    " report outcome
    call s:report_clean(l:deleted, l:failed)
    if !empty(l:failed)
        throw 'ERROR(DelFail): Failed to delete ' . join(l:failed, ', ')
    endif
    if l:arg.pause_end | call s:prompt() | endif
    return v:true  " signals action taken
endfunction

" s:complete_arg(arg)    {{{1

""
" @private
" Completes |Dictionary| {arg} provided to @function(s:clean_output),
" @function(dn#md#cleanBuffer) and @function(dn#md#cleanAllBuffers).
" That is, any default key not present in the provided Dict {arg} is added to
" the Dict with the corresponding default value.
"
" Default {arg} = {   'bufnr': 0,          'confirm': v:false,
"                  'say_none': v:false,  'pause_end': v:false,
"                    'insert': v:false}
"
" @throws InvalidKey if Dict contains an invalid key
" @throws NonBoolVal if non-boolean value assigned to boolean key
" @throws NonDictArg if expected Dict arg and got non-Dict
function! s:complete_arg(arg)
    " must be provided with a Dict arg    {{{2
    if type(a:arg) != type({})
        throw 'ERROR(NonDictArg): Expected dict arg, got '
                    \ . s:variable_type(a:arg)
    endif
    " set boolean keys    {{{2
    let l:boolean_keys = ['confirm', 'insert', 'pause_end', 'say_none']
    " start return Dict arg with default values    {{{2
    let l:arg = {    'bufnr': 0,         'confirm': v:false,
                \   'insert': v:false, 'pause_end': v:false,
                \ 'say_none': v:false}    " }}}2
    " replace return Dict values with provided values if valid    {{{2
    for l:key in keys(a:arg)
        if     l:key ==# 'bufnr'    " {{{3
            let l:arg.bufnr = a:arg.bufnr
        " elseif boolean key    {{{3
        elseif count(l:boolean_keys, l:key)
            let l:value = a:arg[l:key]
            if   type(l:value) == type(v:true)
                let l:arg[l:key] = l:value
            else
                throw 'ERROR(NonBoolVal): Expected bool for "' . l:key
                            \ . '", got ' . s:variable_type(l:value)
            endif
        else   " invalid Dict key    {{{3
            throw 'ERROR(InvalidKey): "' . l:key . '"'
        endif    " }}}3
    endfor
    " return completed arg Dict    {{{2
    return l:arg    " }}}2
endfunction

" s:confirm(question)    {{{1

""
" @private
" Asks user a {question} to be answered with a 'y' or 'n'.
function! s:confirm(question) abort
    echohl Question
    echomsg a:question
    echohl None
    let l:char = nr2char(getchar())
    echon l:char
    return (l:char ==? 'y')
endfunction

" s:delete_output(filepaths, directories)    {{{1

""
" @private
" Attempts to delete {filepaths} and {directories}. Returns a list of
" successfully deleted items and a list of items that could not be deleted.
function! s:delete_output(fps, dirs) abort
    let l:deleted = [] | let l:failed = []
    " the return value from |delete()| is not boolean; it returns 0 if
    " successful and -1 if the deletion fails or partly fails.
    for l:fp in a:fps
        let l:result = delete(l:fp)
        " @function(s:fp_exists) can fail to detect files in special
        " circumstances, so also test return value of |delete()|
        if l:result == -1 || s:fp_exists(l:fp) | call add(l:failed, l:fp)
        else | call add(l:deleted, fnamemodify(l:fp, ':t'))
        endif
    endfor
    for l:dir in a:dirs
        call delete(l:dir, 'rf')  " delete recursively!!
        if isdirectory(l:dir) | call add(l:failed, l:dir)
        else | call add(l:deleted, fnamemodify(l:dir, ':t'))
        endif
    endfor
    " return outcome
    return [l:deleted, l:failed]
endfunction

" s:exception_error(exception)    {{{1

""
" @private
" Extracts error message from Vim exceptions. Other exceptions are returned
" unaltered.
"
" This is useful because vim will not allow Vim errors to be re-thrown. If all
" errors are processed by this function before re-throwing them, there is no
" chance of the re-throw causing this failure.
"
" It also makes the errors a little more easy to read since the Vim context is
" removed. (This context provides little troubleshooting assistance in simple
" scripts.) For that reason this function may usefully be used in processing
" all exceptions before operating on them.
function! s:exception_error(exception) abort
    let l:matches = matchlist(a:exception, '^Vim\%((\a\+)\)\=:\(E\d\+\p\+$\)')
    return (!empty(l:matches) && !empty(l:matches[1])) ? l:matches[1]
                \                                      : a:exception
endfunction

" s:fp_exists(filepath)    {{{1

""
" @private
" Determine whether {filepath} exists.
"
" Vim has limitations in checking for the existence of a file. The method
" employed by this function uses |glob()| and is more robust than using
" |filereadable()| and |filewritable()|. It can still fail, however, if the
" file being tested is in a directory for which the user does not have execute
" permissions.
function! s:fp_exists(fp)
    return !empty(glob(a:fp))
endfunction

" s:rm_dir(key, val)    {{{1

""
" @private
" A |Funcref| intended to be used with a |map()| function to extract a list if
" filenames from a list of filepaths, i.e., by removing ("rm") the directory
" portion of the filepath ("rm_dir"). Uses the standard |Funcref| arguments
" {key} and {val}.
function! s:rm_dir(key, val)
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
        call add(l:options, {'Proceed anyway': v:true})
        call add(l:options, {'Abort': v:false})
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

" s:log(msg)    {{{1

""
" @private
" Write {msg} to log file ~/dn-md-log. Note that {msg} can be a string or list
" of strings.
function! s:log(msg)
    let l:log = $HOME . '/dn-md-log'
    let l:msgs = []
    if     type(a:msg) == type('')
        call add(l:msgs, a:msg)
    elseif type(a:msg) == type([])
        call extend(l:msgs, a:msg)
    else
        call dn#util#error('Invalid log message')
    endif
    call writefile(l:msgs, l:log, 'a')
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
"
" Returns a two item list with the first item being a list of located output
" files and the second item being a list of located output directories.
function! s:output_artefacts(filepath) abort
    let l:filepath = simplify(fnamemodify(a:filepath, ':p'))
    let l:dir = fnamemodify(l:filepath, ':h')
    let l:file = fnamemodify(l:filepath, ':t')
    let l:base = fnamemodify(l:file, ':r')
    " identify deletion candidates
    let l:fps = [] | let l:dirs = []
    for l:suffix in s:clean_suffixes
        let l:candidate = l:dir . '/' . l:base . '.' . l:suffix
        if s:fp_exists(l:candidate) | call add(l:fps, l:candidate) | endif
    endfor
    for l:subdir in s:clean_dirs
        let l:candidate = l:dir . '/' . l:subdir
        if isdirectory(l:candidate) | call add(l:dirs, l:candidate) | endif
    endfor
    return [l:fps, l:dirs]
endfunction

" s:prompt()    {{{1

""
" @private
" Prompt user to press the "Enter" key to continue.
function! s:prompt() abort
    let l:prompt = 'Press [Enter] to continue...'
    echohl MoreMsg
    call input(l:prompt)
    echohl Normal
    echo "\n"
endfunction

" s:report_clean(deleted, failed)    {{{1

""
" @private
" Report on outcome of output cleaning. The report is based on a list of
" [deleted] files and directories, and a list of files and directories that
" [failed] to be deleted.
function! s:report_clean(deleted, failed) abort
    if !empty(a:deleted)
        echomsg 'Deleted ' . join(a:deleted, ', ')
    endif
    if !empty(a:failed)
        echomsg 'Errors occurred trying to delete:'
        for l:path in a:failed | echomsg '- ' . l:path | endfor
    endif
endfunction

" s:utils_missing()    {{{1

""
" @private
" Determines whether dn-utils plugin is loaded.
function! s:utils_missing() abort
    silent! call dn#util#rev()  " load function if available
    if exists('*dn#util#rev') && dn#util#rev() =~? '\v^\d{8,}$'
        return v:false
    else
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return v:true
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
" @throws NoBuffer if no buffer has specified buffer number
" @throws NoFile if specified buffer has no associated file
" @throws NonMDBuffer if specified buffer does not have a markdown filetype
" @throws WrongBufNrType if buffer number value is not a number
function! s:valid_bufnr(bufnr) abort
    " check params
    if type(a:bufnr) != type(0)  " check bufnr data type
        throw 'ERROR(WrongBufNrType): For buffer number got a '
                    \ . s:variable_type(a:bufnr) . ': '
                    \ . dn#util#stringify(a:bufnr)
    endif
    if !bufexists(a:bufnr)  " check bufnr exists
        throw 'ERROR(NoBuffer): Buffer ' . a:bufnr . ' does not exist'
    endif
    if empty(bufname(a:bufnr))  " check buffer associated with a file
        throw 'ERROR(NoFile): Buffer ' . a:bufnr . ' has no associated file'
    endif
    let l:ft = getbufvar(a:bufnr, '&filetype')  " check buffer file type
    if !s:md_filetype(l:ft)
        throw 'ERROR(NonMDBuffer): Buffer ' . a:bufnr
                    \ . ' has filetype: ' . l:ft
    endif
    " valid if survived tests
    return v:true
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

" dn#md#addBoilerplate([insert])    {{{1

""
" @public
" Adds panzer/markdown boilerplate to the top and bottom of the document.
"
" The [insert] boolean argument determines whether or not the function was
" entered from insert mode.
" @default insert=false
function! dn#md#addBoilerplate(...) abort
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
    if l:insert | call dn#util#insertMode(v:true) | endif
endfunction

" dn#md#cleanAllBuffers(arg)    {{{1

" - in block below @default must be a single line to be processed correctly by
"   vimdoc, so take care when formatting, e.g., with |gq|

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
" Optional [arg] is a |Dictionary| with a number of valid keys, all of which
" are themselves optional:
"
" key "confirm" (bool)
" * whether, if output artefacts are detected, to ask user for confirmation
"   before anything is deleted
" 
" key "insert" (bool)
" * whether or not the function was entered from insert mode
" 
" key "pause_end" (bool)
" * whether to pause after action taken; will not pause if no actions taken
"   and no feedback provided
"
" key "say_none" (bool)
" * whether to display a message if no output artefacts are detected
" 
" @default arg={'confirm': false, 'insert': false, 'pause_end': false, 'say_none': false}
"
" @throws ArgCount if wrong number of arguments
" @throws DelFail if fail to delete output files/directories
" @throws InvalidKey if Dict contains an invalid key
" @throws NoBuffer if no buffer has specified buffer number
" @throws NoFile if specified buffer has no associated file
" @throws NonBoolVal if non-boolean value assigned to boolean key
" @throws NonDictArg if expected Dict arg and got non-Dict
" @throws NonMDBuffer if specified buffer does not have a markdown filetype
" @throws WrongBufNrType if buffer number value is not a number
function! dn#md#cleanAllBuffers(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:utils_missing() | return | endif  " requires dn-utils plugin
    " process params
    if a:0 > 1 | throw 'ERROR(ArgCount): Expected 1 arg, got ' . a:0 | endif
    let l:arg = s:complete_arg(a:0 ? a:1 : {})
    " cycle through buffers, acting only on those with markdown files
    for l:bufnr in range(1, bufnr('$'))
        if !bufexists(l:bufnr) | continue | endif
        if empty(bufname(l:bufnr)) | continue | endif
        let l:filetype = getbufvar(l:bufnr, '&filetype')
        if !s:md_filetype(l:filetype) | continue | endif
        let l:arg.bufnr = l:bufnr
        try   | call s:clean_output(l:arg)
        catch | throw s:exception_error(v:exception)
        endtry
    endfor
    " return to calling mode
    if l:arg.insert | call dn#util#insertMode(v:true) | endif
endfunction

" dn#md#cleanBuffer([arg])    {{{1

" - in block below @default must be a single line to be processed correctly by
"   vimdoc, so take care when formatting, e.g., with |gq|

""
" @public
" Deletes common output artefacts: output files with extensions "htm", "html",
" "pdf", "epub", and "mobi"; and temporary directories names ".tmp".
"
" Optional [arg] is a |Dictionary| with a number of valid keys, all of which
" are themselves optional:
"
" key "bufnr" (number)
" * buffer number to process for output
"
" key "confirm" (bool)
" * whether, if output artefacts are detected, to ask user for confirmation
"   before anything is deleted
" 
" key "insert" (bool)
" * whether or not the function was entered from insert mode
"
" key "pause_end" (bool)
" * whether to pause after action taken; will not pause if no actions taken
"   and no feedback provided
" 
" key "say_none" (bool)
" * whether to display a message if no output artefacts are detected
" 
" @default arg={'bufnr': 0, 'confirm': false, 'insert': false, 'pause_end': false, 'say_none': false}
"
" @throws ArgCount if wrong number of arguments
" @throws DelFail if fail to delete output files/directories
" @throws InvalidKey if Dict contains an invalid key
" @throws NoBuffer if no buffer has specified buffer number
" @throws NoFile if specified buffer has no associated file
" @throws NonBoolVal if non-boolean value assigned to boolean key
" @throws NonDictArg if expected Dict arg and got non-Dict
" @throws NonMDBuffer if specified buffer does not have a markdown filetype
" @throws WrongBufNrType if buffer number value is not a number
function! dn#md#cleanBuffer(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:utils_missing() | return | endif  " requires dn-utils plugin
    " params
    if a:0 > 1 | throw 'ERROR(ArgCount): Expected 1 arg, got ' . a:0 | endif
    let l:arg = s:complete_arg(a:0 ? a:1 : {})
    " clean output files
    call s:clean_output(l:arg)
    " return to calling mode
    if l:arg.insert | call dn#util#insertMode(v:true) | endif
endfunction

" dn#md#insertFigure([insert])    {{{1

""
" @public
" Inserts a figure on a new line.
"
" The [insert] boolean argument determines whether or not the function was
" entered from insert mode.
" @default insert=false
function! dn#md#insertFigure(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " insert figure
    call s:insert_figure()
    " return to calling mode
    if l:insert | call dn#util#insertMode(v:true) | endif
endfunction

" dn#md#panzerifyMetadata([insert])    {{{1

""
" @public
" Adds a line to the initial metadata block, if present, for panzer styles.
" Intended for use when converting from plain pandoc to pandoc-plus-panzer.
"
" The [insert] boolean argument determines whether or not the function was
" entered from insert mode.
" @default insert=false
 "@throws NoBlockEnd if can't find end of initial metadata block
" @throws NoMetadata if no initial metadata block
function! dn#md#panzerifyMetadata(...) abort
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
            throw "ERROR(NoMetadata): Can't find initial yaml metadata block"
        endif
        call cursor(1, 1)
        let l:end_metadata = search('^\(---\|\.\.\.\)\s*$', 'W')
        if !l:end_metadata
            throw "ERROR(NoBlockEnd): Can't find end of top metadata block"
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
    if l:insert | call dn#util#insertMode(v:true) | endif
endfunction
" }}}1

" Control statements    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :
