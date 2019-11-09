" Vim ftplugin for markdown
" Last change: 2018 Aug 18
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
" @order intro config features commands mappings autocmds functions help
" An auxiliary filetype plugin for the markdown language.
"
" Previously the plugin author used a personal plugin to provide markdown-
" related functionality. That plugin was retired when the plugin author
" switched to the |vim-pandoc| plugin and panzer framework
" (https://github.com/msprev/panzer) for markdown support. The @plugin(name)
" ftplugin is intended to address any gaps in markdown support provided by
" those tools.
"
" @subsection Dependencies
"
" Pandoc is used to generate output. It is not provided by the @plugin(name)
" ftplugin, which depends on the |vim-pandoc| plugin and assumes panzer
" (https://github.com/msprev/panzer) is installed and configured.
"
" The @plugin(name) ftplugin is designed for use with pandoc version 2.0. At
" the time of writing this is the development branch of pandoc, while the
" production version is 1.19. As the change in major version number suggests,
" the interfaces of these two versions of pandoc are incompatible. Hence, the
" @plugin(name) ftplugin will not work with the current production version of
" pandoc. There are two known incompatibilities between these versions that
" affect the @plugin(name) ftplugin. The first is that the "smart" feature has
" changed from an option ("--smart") to an extension
" ("--from=markdown+smart"). The second is a change in the option used to
" specify the latex engine from "--latex-engine" to "--pdf-engine".
"
" The @plugin(name) ftplugin also depends on the vim-dn-utils plugin
" (https://github.com/dnebauer/vim-dn-utils).

""
" @section Features, features
" The major features of the @plugin(name) ftplugin are support for yaml
" metadata blocks, adding figures, cleaning up output file and directories,
" and altering the pandoc command line arguments.
"
" @subsection Metadata
"
" Pandoc-flavoured markdown uses a yaml-style metadata block at the top of the
" file to specify values used by pandoc for document processing. With panzer
" (https://github.com/msprev/panzer) installed the metadata block can also
" specify panzer-related values which, in turn, specify values used by pandoc
" for document processing.
"
" The @plugin(name) ftplugin assumes the following default yaml-metadata block
" is used at the top of documents:
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
" The @plugin(name) ftplugin leaves the bulk of output generation to
" |vim-pandoc|, but does generate mobi output since pandoc, and hence
" |vim-pandoc| does not handle mobi format (see @function(dn#md#generateMobi)
" and @command(Mobi)).
"
" The @plugin(name) ftplugin does provide a mapping, command and function for
" deleting output files and temporary output directories. The term "clean" is
" used, as in the makefile keyword that deletes all working and output files.
"
" Cleaning of output only occurs if the current buffer contains a file. The
" directory searched for items to delete is the directory in which the file in
" the current buffer is located.
"
" If the file being edited is FILE.ext, the files that will be deleted have
" names like "FILE.html" and "FILE.pdf" (see @function(dn#md#cleanBuffer)
" for a complete list). The temporary output subdirectory ".tmp" will also be
" recursively force deleted. Warning: the @plugin(name) ftplugin does not
" check that it is safe to delete files and directories identified for
" deletion. For example, it does not check whether any of them are symlinks to
" other locations. Also be aware that directories are forcibly and recursively
" deleted, as with the *nix shell command "rm -fr".
"
" When a markdown buffer is closed (actually when the |BufDelete| event
" occurs), the @plugin(name) ftplugin checks for output files/directories and,
" if any are found, asks the user whether to delete them. If the user confirms
" deletion they are removed. When vim exits (actually, when the |VimLeavePre|
" event occurs) the @plugin(name) ftplugin looks for any markdown buffers and
" looks in their respective directories for output files/directories and, if
" any are found, asks the user whether to delete them. See @section(autocmds)
" for further details.
" 
" Output files and directories associated with the current buffer can be
" deleted at any time by using the @function(dn#md#cleanBuffer) function,
" which can be called using the command @command(MUCleanOutput) and mapping
" "<Leader>co" (see @section(mappings)).
"
" @subsection Altering pandoc compiler arguments
"
" The |vim-pandoc| plugin provides the |String| variable
" |g:pandoc#compiler#arguments| for users to configure. Any arguments it
" contains are automatically passed to pandoc when the |:Pandoc| command is
" invoked. The @plugin(name) ftplugin enables the user to make changes to the
" arguments configured by this variable. The parser used by @plugin(name) is
" very simple, so all arguments in the value for |g:pandoc#compiler#arguments|
" must be separated by one or more spaces and have one of the following forms:
" * --arg-with-no-value
" * --arg="value"
"
" The number of leading dashes can be from one to three.
"
" To add an argument and value such as "-Vlang:spanish", treat it as though it
" were an argument such as "--arg-with-no-value".
"
" This is only one method of specifying compiler arguments. For example,
" another method is using the document yaml metadata block. If highlight style
" is specified by multiple methods, the method that "wins" may depend on a
" number of factors. Trial and error may be necessary to determine how
" different methods of setting compiler arguments interact on a particular
" system.
"
" The @plugin(name) ftplugin provides commands for adding and/or changing the
" following pandoc command line argument:
"
" --highlight-style
"   * see @command(MUChangeHighlightStyle)
"   * user selects from available highlight styles
"   * advises user of current value if already set

""
" @setting b:disable_dn_md_utils
" Prevents the @plugin(name) ftplugin loading if set to a true value before it
" would normally load.

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

" s:ebook_metadata - template of ebook metadata structure    {{{1

""
" An internal data structure used for manipulating ebook tags. It is
" not used directly but copied to a local function variable.
let s:ebook_metadata = {
            \ 'title': {
            \   'explain' : '',
            \   'item'    : 'Title:       %',
            \   'prompt'  : 'Enter title:',
            \   'option'  : '--title',
            \   'value'   : '',
            \   },
            \ 'authors': {
            \   'explain' : 'Multiple authors = First Last & First Last',
            \   'item'    : 'Author(s):   %',
            \   'prompt'  : 'Enter authors (separate with &):',
            \   'option'  : '--authors',
            \   'value'   : '',
            \   },
            \ 'series': {
            \   'explain' : '',
            \   'item'    : 'Series: %',
            \   'prompt'  : 'Enter series name:',
            \   'option'  : '--series',
            \   'value'   : '',
            \   },
            \ 'index': {
            \   'explain' : '',
            \   'item'    : 'Series index: %',
            \   'prompt'  : 'Enter position in series:',
            \   'option'  : '--series-index',
            \   'value'   : '',
            \   },
            \ 'cover': {
            \   'explain' : 'Cover image can be a jpg, png or gif file',
            \   'item'    : 'Cover image: %',
            \   'prompt'  : 'Enter cover image file path:',
            \   'option'  : '--cover',
            \   'value'   : '',
            \   },
            \ }

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
            \ '        # Latex8-12|14|17|20pt; PaginateSections; IncludeFiles'
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
" @function(dn#md#cleanOutput) for a complete list.)
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
    let l:md_fp = simplify(fnamemodify(bufname(l:arg.bufnr), ':p'))
    let [l:fps, l:dirs] = s:output_artefacts(l:md_fp)
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

" s:generate_mobi()    {{{1

""
" @private
" Create a mobi file from an epub file using 'ebook-convert'. The user is able
" to specify a new or replacement cover image.
"
" If 'ebook-meta' is available, further changes can be made to metadata: the
" user can edit the title and author. Also, as the mobi format does not
" support the series and series-index tags, these are incorporated into the
" title as 'series - index - title'.
" 
" No value is returned.
" @throws BadMeta if metadata output is invalid
" @throws ConversionFailed if unable to convert epub file to mobi
" @throws NoConverter if cannot find ebook coverter executable
" @throws NoEpub if no epub output file available to convert
" @throws NoMeta if not able to extract epub metadata
" @throws NoMobi if no mobi file created during epub conversion
function! s:generate_mobi() abort
    " variables
    let l:epub = substitute(expand('%'), '\.md$', '.epub', '')
    let l:converter = 'ebook-convert'
    let l:extractor = 'ebook-meta'
    let l:ebook_metadata = deepcopy(s:ebook_metadata)
    " need epub file as source
    if !filereadable(l:epub)
        throw 'ERROR(NoEpub): No epub output file available to convert'
    endif
    " need ebook converter
    if !executable(l:converter)
        throw 'ERROR(NoConverter): Cannot find ' . l:converter
    endif
    " check for cover image
    " - has same basename as epub
    let l:covers = []
    for l:ext in ['.jpg', '.png', '.gif']
        let l:cover = substitute(expand('%'), '\.md$', l:ext, '')
        if filereadable(l:cover)
            call add(l:cover, l:cover)
        endif
    endfor
    if len(l:covers) >= 1
        " found at least one cover
        let l:msg = 'Found possible cover '
        let l:msg .= len(l:covers) == 1 ? 'image:' : 'images:'
        echo l:msg
        for l:cover in l:covers
            echo '  - ' . l:cover
        endfor
        let l:cover = l:covers[0]
        echo "Selecting '" . l:cover . "' as cover image"
        let l:ebook_metadata.cover.value = l:cover
    endif
    " check for editable metadata values
    if executable(l:extractor)
        let l:cmd = [l:extractor, l:epub]
        let l:meta_output = systemlist(l:cmd)
        if v:shell_error
            " l:meta_output now contains shell error feedback
            let l:err = ['Unable to extract metadata from epub output file']
            if !empty(l:meta_output)
                call map(l:meta_output, '"  " . v:val')
                call extend(l:err, ['Error message:'] + l:meta_output)
            endif
            call dn#util#warn(l:err)
            throw 'ERROR(NoMeta) Unable to extract epub metadata'
        endif
        " - metadata output includes lines like:
        "     'Author(s)           : Seanan A. McGuire'
        "     'Series              : Velveteen vs. #1'
        "   where the Series field combines the 'series' tag value, in this
        "   case 'Velveteen vs.', and the 'series-index' tag value, in this
        "   case '1'
        " - the regex below returns multiple matches: \1 is the tag name,
        "   \2 is the tag value, and \3 is the series index for a series tag
        " - if used with matchlist, [0] is the total string while [1], [2],
        "   and [3] correspond to \1, \2 and \3, respectively
        let l:re_meta = '\m^\([^:]\{-1,}\)\s\{}:\s'
                    \ . '\(.\{-1,}\)'
                    \ . '\%(\s#\([^#\s]\{-1,}\)\)\?$'
        for l:line in l:meta_output
            let l:matches = matchlist(l:line, l:re_meta)
            if empty(l:matches) | continue | endif
            let l:match_len = len(l:matches)
            " extract tag name and value, and possibly series index
            let l:tag = v:null | let l:val = v:null | let l:index = v:null
            if l:match_len < 3 || l:match_len > 4
                throw "ERROR(BadMeta) Invalid metadata '" . l:line . "'"
            endif
            let l:tag = l:matches[1]
            let l:val = l:matches[2]
            if l:match_len == 4
                let l:index = l:matches[3]
            endif
            if !empty(l:index) && l:tag !~# '\m^Series'
                throw "ERROR(BadMeta) Invalid metadata '" . l:line . "'"
            endif
            " assign tag details to correct tag
            for [l:name, l:details] in items(l:ebook_metadata)
                " first handle case of series ± index
                if l:tag =~# '\m^Title' 
                    let l:ebook_metadata.title.value = l:val
                elseif l:tag =~# '\m^Author' 
                    let l:ebook_metadata.authors.value = l:val
                elseif l:tag =~# '\m^Series'
                    let l:ebook_metadata.series.value = l:val
                    if !empty(l:index)
                        let l:ebook_metadata.index.value = l:index
                    endif
                endif
            endfor
        endfor
        " sanity checks
        if empty(l:ebook_metadata.title.value)
            call dn#util#warn('Could next find the epub title')
        endif
        if empty(l:ebook_metadata.authors.value)
            call dn#util#warn('Could next find the epub authors')
        endif
        " incorporate series ± index into title
        if !empty(l:ebook_metadata.series.value)
            let l:title = l:ebook_metadata.series.value
            if !empty(l:ebook_metadata.index.value)
                let l:title .= ' - ' . l:ebook_metadata.index.value
            endif
            if !empty(l:ebook_metadata.title.value)
                let l:title .= ' - ' . l:ebook_metadata.title.value
            endif
            let l:ebook_metadata.title.value = l:title
            echo 'Mobi format does not support series or series index tags'
            echo 'Incorporating them into the title'
        endif
        " done now with series and series index
        call remove(l:ebook_metadata, 'series')
        call remove(l:ebook_metadata, 'index')
    else
        echo "Cannot find executable '" . l:extractor . "'"
        echo '- unable to extract metadata for editing'
        for l:tag in ['author', 'title', 'series', 'index']
            call remove(l:ebook_metadata, l:tag)
        endfor
    endif
    " give user opportunity to edit extracted values
    while v:true
        let l:prompt = 'Select an entry to edit (empty value if done)'
        let l:menu = {}
        for [l:tag, l:details] in items(l:ebook_metadata)
            let l:val = empty(l:details.value) ? '⸺' : l:details.value
            let l:item = substitute(l:details.item, '%', l:val, '')
            let l:menu[l:item] = l:tag
        endfor
        let l:pick = dn#util#menuSelect(l:menu, l:prompt)
        if empty(l:pick) | break | endif
        if !empty(l:ebook_metadata[l:pick]['explain'])
            echo l:ebook_metadata[l:pick]['explain']
        endif
        let l:details = l:ebook_metadata[l:pick]
        let l:input = input(l:details.prompt, l:details.value, 'file')
        let l:details.value = l:input
    endwhile
    " creat mobi file
    let l:mobi = substitute(expand('%'), '\.md$', '.mobi', '')
    let l:opts = ['--pretty-print', '--mobi-file-type=both',
                \ '--insert-blank-line', '--insert-metadata']
    let l:cmd = [l:converter, l:epub, l:mobi]
    call extend(l:cmd, l:opts)
    for [l:tag, l:details] in items(l:ebook_metadata)
        if !empty(l:details.value)
            let l:opt = l:details.option . shellescape(l:details.value)
            call add(l:cmd, l:opt)
        endif
    endfor
    let l:conversion_output = systemlist(l:cmd)
    if v:shell_error
        " l:conversion_output now contains shell error feedback
        let l:err = ['Unable to create mobi file from epub file']
        if !empty(l:conversion_output)
            call map(l:conversion_output, '"  " . v:val')
            call extend(l:err, ['Error message:'] + l:conversion_output)
        endif
        call dn#util#warn(l:err)
        throw 'ERROR(ConversionFailed) Unable to convert epub file to mobi'
    endif
    if !filereadable(l:mobi)
        throw 'ERROR(NoMobi) No mobi file created during epub conversion'
    endif
    return
endfunction

" s:highlight_styles_available()    {{{1

""
" @private
" Gets available pandoc highlight styles. This is done by executing the shell
" command
" >
"     pandoc --list-highlight-styles
" <
" and capturing the output. Returns a |List|.
" @throws NoStyles if unable to get highlight styles from pandoc
function! s:highlight_styles_available() abort
    let l:cmd = ['pandoc', '--list-highlight-styles']
    let l:styles = systemlist(l:cmd)
    if v:shell_error
        " l:styles now contains shell error feedback
        let l:err = ['Unable to obtain highlight styles from pandoc']
        if !empty(l:styles)
            call map(l:styles, '"  " . v:val')
            call extend(l:err, ['Error message:'] + l:styles)
        endif
        call dn#util#warn(l:err)
        throw 'ERROR(NoStyles) Unable to obtain pandoc highlight styles'
    endif
    return l:styles
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

" s:insert_highlight_language()    {{{1

""
" @private
" Select a code block highlight language and insert it at the end of the
" current line.
" @throws NoLangs if unable to get highlight languages from pandoc
" @throws BadLang if user enters an invalid highlight language
function! s:insert_highlight_language() abort
    " obtain highlight language from user
    echo 'The Tab key provides language completion.'
    let l:prompt = 'Enter highlight language (empty to abort): '
    let l:complete = 'customlist,dn#md#_highlightLanguageCompletion'
    try   | let l:lang = input(l:prompt, '', l:complete)
    catch | throw dn#util#exceptionError(v:exception)
    endtry
    if empty(l:lang) | return | endif
    try   | let l:valid_langs = dn#md#_highlightLanguagesSupported()
    catch | throw dn#util#exceptionError(v:exception)
    endtry
    let l:err = "ERROR(BadLang): Invalid highlight language '" . l:lang . "'"
    if !count(l:valid_langs, l:lang) | throw l:err | endif
    " insert highlight language at current cursor location
    silent execute 'normal! A' . l:lang
    return
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
" @function(dn#md#cleanBuffer) for a complete list.) Uses directory and base
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

" s:parsed_compiler_args()    {{{1

""
" @private
" Parses |g:pandoc#compiler#arguments| to extract arguments into a |Dict|.
" Assumes all arguments in the |g:pandoc#compiler#arguments| |String| are
" separated by one or more spaces and have one of the following forms:
" * --arg-with-no-value
" * --arg="value"
"
" The number of leading dashes can be from one to three.
"
" To add an argument and value such as "-Vlang:spanish", treat it as though it
" were an argument such as "--arg-with-no-value".
"
" The |Dict| that is returned by this function has entries like:
" >
"     {'--arg-with-no-value': v:null, '---arg': 'value'}
" <
"
" Returns an empty |Dict| if |g:pandoc#compiler#arguments| does not exist.
" @throws BadParse if unable to parse g:pandoc#compiler#arguments
function! s:parsed_compiler_args() abort
    " handle case where no compiler args are set (the default)
    if !exists('g:pandoc#compiler#arguments')
                \ || empty(g:pandoc#compiler#arguments)
        return {}
    endif
    let l:parse_err = "ERROR(BadParse): Can't parse"
                \   . ' g:pandoc#compiler#arguments'
    let l:args = {}
    " match either '[-]--arg' or '[-]--arg="val"', then remainder
    let l:arg_re = '\v^ *(-{1,3}[^ \=]+%(\="[^"]+")?) *(.*)$'
    " match parts of two-part arg like '[-]--arg="val"'
    let l:two_parts_re = '\v^(-{1,3}[^ \=]+)\="([^"]+)"$'
    let l:remainder = g:pandoc#compiler#arguments
    " each loop, extract first arg then pass remainder to next loop
    while 1
        let l:arg_matches = matchlist(l:remainder, l:arg_re)
        if empty(l:arg_matches)
            " means got all matches, but error if cmdline not exhausted
            if !empty(l:remainder) | throw l:parse_err | endif
            break
        endif
        let l:arg = l:arg_matches[1]
        " if one-part arg, add to Dict with null value
        " if two part arg, extract parts with Dict key=option and value=value
        let l:two_parts = matchlist(l:arg, l:two_parts_re)
        if   empty(l:two_parts) | let l:args[l:arg] = v:null
        else                    | let l:args[l:two_parts[1]] = l:two_parts[2]
        endif
        " have processed arg match, now pass remainder to next loop
        let l:remainder = l:arg_matches[2]
    endwhile
    return l:args
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

" s:rebuild_compiler_args(args)    {{{1

""
" @private
" Rebuilds |vim-pandoc| plugin's |String| variable
" |g:pandoc#compiler#arguments| from {args} |Dict|. For arguments of type
" "--arg" {args} uses an entry with key "--arg" and value |v:null|. For
" arguments of type "--arg=something" {args} uses an entry with key "--arg"
" and value "something". There can be from one to three dashes. For arguments
" of the form "-Vlang:spanish" treat the compound as a single argument.
" @throws BadArgType if argument exists and is not a |Dict|
function! s:rebuild_compiler_args(args) abort
    if type(a:args) != type({})
        throw 'Error(BadArgType): Invalid argument: ' . string(a:args)
    endif
    " loop through Dict entries
    let l:arg_string = ''
    for l:arg in sort(keys(a:args))  " sort to ensure predictability
        let l:val = a:args[l:arg]
        let l:val_type = type(l:val)
        if len(l:arg_string) > 0 | let l:arg_string .= ' ' | endif
        if l:val is v:null
            let l:arg_string .= l:arg
        elseif l:val_type == type(0) || l:val_type == type(0.0)
            let l:arg_string .= l:arg . '=' . l:val
        elseif l:val_type == type('')
            let l:arg_string .= l:arg . '="' . l:val . '"'
        else  " handle only string, float, number and null values
            echohl Error
            echo 'Invalid pandoc compiler argument: ' 
                        \ . l:arg . '=' . string(l:val)
            echohl Normal
        endif
    endfor
    let g:pandoc#compiler#arguments = l:arg_string
    return
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
" exists and is associated with a file. For the purposes of the @plugin(name)
" ftplugin a buffer number is invalid if it is not associated with a file
" name. This aligns with the behaviour of pandoc since it will not generate
" output if a buffer is not associated with a file. This also means an error
" will be generated for the edge case where a user has created a buffer and
" set a markdown filetype, but not saved the buffer as a file.
"
" For the purposes of the @plugin(name) ftplugin a buffer is also invalid if
" it does not have a markdown filetype.
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

" dn#md#_highlightLanguageCompletion(arg, line, pos)    {{{1

""
" @private
" Custom command completion for highlight language, accepting the required
" arguments of {arg}, {line}, and {pos} although the latter two are not used
" (see |:command-completion-customlist|). Returns a |List| of highlight
" languages.
function! dn#md#_highlightLanguageCompletion(arg, line, pos)
    let l:langs = dn#md#_highlightLanguagesSupported()
    return filter(l:langs, {idx, val -> val =~ a:arg})
endfunction

" dn#md#_highlightLanguagesSupported()    {{{1

""
" @private
" Gets supported pandoc highlight languages. This is done by executing the
" shell command
" >
"     pandoc --list-highlight-languages
" <
" and capturing the output. Returns a |List|.
" @throws NoLangs if unable to get highlight languages from pandoc
function! dn#md#_highlightLanguagesSupported() abort
    let l:cmd = ['pandoc', '--list-highlight-languages']
    let l:langs = systemlist(l:cmd)
    if v:shell_error
        " l:langs now contains shell error feedback
        let l:err = ['Unable to obtain highlight languages from pandoc']
        if !empty(l:langs)
            call map(l:langs, '"  " . v:val')
            call extend(l:err, ['Error message:'] + l:langs)
        endif
        call dn#util#warn(l:err)
        throw 'ERROR(NoLangs) Unable to obtain pandoc highlight languages'
    endif
    return l:langs
endfunction
" }}}1

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

" dn#md#changeHighlightStyle()    {{{1

""
" @public
" Change the existing pandoc highlight style, as set by the pandoc option
" "--highlight-style". The user is informed of the existing highlight style
" and then given the option to select from a list of available highlight
" styles. The highlight style setting is added to the |vim-pandoc| module
" variable |g:pandoc#compiler#arguments|; if the highlight style is already
" defined in the |g:pandoc#compiler#arguments| variable, the variable value is
" adjusted to reflect the new style.
"
" The parser used for the variable |g:pandoc#compiler#arguments| is simple and
" there are limitations to the syntax that can be used for
" |g:pandoc#compiler#arguments|. For more details on the formatting of this
" variable, and the limitations of this method of specifying pandoc compiler
" arguments, see subsection "ALTERING PANDOC COMPILER ARGUMENTS" in
" @section(features).
" @throws BadParse if unable to parse g:pandoc#compiler#arguments
" @throws NoStyles if unable to get available highlight styles
function! dn#md#changeHighlightStyle() abort
    " universal tasks
    echo '' |  " clear command line
    if s:utils_missing() | return | endif  " requires dn-utils plugin
    " parse existing compiler args
    try
        let l:args = s:parsed_compiler_args()
    catch
        call dn#util#error(s:exception_error(v:exception))
        return
    endtry
    " get available highlight styles
    try
        let l:styles = s:highlight_styles_available()
    catch
        call dn#util#error(s:exception_error(v:exception))
        return
    endtry
    " provide feedback
    if has_key(l:args, '--highlight-style')
        echo "Compiler arguments already include '--highlight-style'"
                    \ . " setting of '" . l:args['--highlight-style'] . "'"
    elseif count(l:styles, 'pygments')
        echo 'Highlight style is not currently set via the'
                    \ . ' g:pandoc#compiler#arguments variable'
        echo "Highlight style will default to 'pygments' if not"
                    \ . ' defined by another method'
    else
        echo 'Highlight style is not currently set via the'
                    \ . ' g:pandoc#compiler#arguments variable'
    endif
    " select highlight style
    let l:style = dn#util#menuSelect(l:styles, 'Select highlight style:')
    if empty(l:style) | return | endif
    " rebuild compiler arguments
    let l:args['--highlight-style'] = l:style
    try
        call s:rebuild_compiler_args(l:args)
        echomsg 'Highlight style set to "' . l:style . '"'
    catch
        call dn#util#error(dn#util#exceptionError(v:exception))
        return
    endtry
    return
endfunction

" dn#md#cleanAllBuffers(arg)    {{{1

" - in block below @default must be a single line to be processed correctly by
"   vimdoc, so take care when formatting, e.g., with |gq|

""
" @public
" Deletes common output artefacts: output files with extensions like "html"
" and "pdf", and temporary directories like ".tmp". (See
" @function(dn#md#cleanBuffer) for a complete list.)
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

" dn#md#generateMobi([insert])    {{{1

""
" @public
" Generates a mobi output file from an existing epub output file.
"
" The [insert] boolean argument determines whether or not the function was
" entered from insert mode.
" @default insert=false
" @throws BadMeta if metadata output is invalid
" @throws ConversionFailed if unable to convert epub file to mobi
" @throws NoConverter if cannot find ebook coverter executable
" @throws NoEpub if no epub output file available to convert
" @throws NoMeta if not able to extract epub metadata
" @throws NoMobi if no mobi file created during epub conversion
function! dn#md#generateMobi(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " generate mobi
    try
        call s:generate_mobi()
    catch
        echo ' '
        call dn#util#error(dn#util#exceptionError(v:exception))
    endtry
    " return to calling mode
    if l:insert | call dn#util#insertMode(v:true) | endif
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

" dn#md#insertHighlightLanguage([insert])    {{{1

""
" @public
" Select a code block highlight language which is inserted at the end of the
" current line.
"
" The [insert] boolean argument determines whether or not the function was
" entered from insert mode.
" @default insert=false
" @throws NoLangs if unable to get highlight languages from pandoc
" @throws BadLang if user enters an invalid highlight language
function! dn#md#insertHighlightLanguage(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " insert figure
    try
        call s:insert_highlight_language()
    catch
        echo ' '
        call dn#util#error(dn#util#exceptionError(v:exception))
    endtry
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
