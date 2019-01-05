" Control statements    {{{1
set encoding=utf-8
scriptencoding utf-8

if exists('b:disable_dn_md_utils') && b:disable_dn_md_utils | finish | endif
if exists('b:loaded_dn_md_utils_mappings') | finish | endif
let b:loaded_dn_md_utils_mappings = 1
if exists('g:no_plugin_maps') && g:no_plugin_maps | finish | endif

""
" @setting g:no_markdown_maps
" Prevents loading of plugin mappings if set to a true value. (See also
" discussion of "g:no_plugin_maps" in @section(mappings).)

""
" @setting g:no_md_maps
" Prevents loading of plugin mappings if set to a true value. (See also
" discussion of "g:no_plugin_maps" in @section(mappings).)

let s:save_cpo = &cpoptions
set cpoptions&vim

" Documentation    {{{1
" - vimdoc does not automatically generate mappings section

""
" @section Mappings, mappings
" The following mappings are provided for both |Insert-mode| and
" |Normal-mode|:
"
" <Leader>ab
"   * add markdown boilerplate
"   * calls @function(dn#md#addBoilerplate)
"
" <Leader>co
"   * clean output files and temporary directories
"   * calls @function(dn#md#cleanBuffer)
"
" <Leader>fig
"   * insert figure on the following line
"   * calls @function(dn#md#insertFigure)
"
" <Leader>hl
"   * user selects a code block highlight language to insert at the cursor
"     location
"   * calls @function(dn#md#insertHighlightLanguage)
"
" <Leader>pm
"   * convert yaml metadata block to use panzer
"   * calls @function(dn#md#panzerifyMetadata)
"
" @plugin(name) adheres to the convention that plugin mappings are not loaded
" if any of the variables "g:no_plugin_maps", |g:no_md_maps| or
" |g:no_markdown_maps| are set to a true value.

" }}}1

" Mappings

" \ab  - add markdown boilerplate    {{{1

""
" Calls @function(dn#md#addBoilerplate) from |Insert-mode| and |Normal-mode|
" to add a metadata header template, including title, author, date, and
" (panzer) styles, and a footer template for url reference links.
if !hasmapto('<Plug>DnABI')
    imap <buffer> <unique> <LocalLeader>ab <Plug>DnABI
endif
imap <buffer> <unique> <Plug>DnABI
            \ <Esc>:call dn#md#addBoilerplate(v:true)<CR>
if !hasmapto('<Plug>DnABN')
    nmap <buffer> <unique> <LocalLeader>ab <Plug>DnABN
endif
nmap <buffer> <unique> <Plug>DnABN
            \ :call dn#md#addBoilerplate()<CR>

" \co  - clean output    {{{1

""
" Calls @function(dn#md#cleanBuffer) from |Insert-mode| and |Normal-mode| to
" delete output files and temporary output directories.
if !hasmapto('<Plug>DnCOI')
    imap <buffer> <unique> <LocalLeader>co <Plug>DnCOI
endif
imap <buffer> <unique> <Plug>DnCOI
            \ <Esc>:call dn#md#cleanBuffer({   'bufnr': bufnr('%'),
            \                               'say_none': v:true,
            \                                 'insert': v:true})<CR>
if !hasmapto('<Plug>DnCON')
    nmap <buffer> <unique> <LocalLeader>co <Plug>DnCON
endif
nmap <buffer> <unique> <Plug>DnCON
            \ :call dn#md#cleanBuffer({   'bufnr': bufnr('%'),
            \                          'say_none': v:true})<CR>

" \fig - insert figure    {{{1

""
" Calls @function(dn#md#insertHighlightLanguage) from |Insert-mode| and
" |Normal-mode| to have the user select a code block highlight language which
" is inserted at the end of the current line.
if !hasmapto('<Plug>DnHLI')
    imap <buffer> <unique> <LocalLeader>hl <Plug>DnHLI
endif
imap <buffer> <unique> <Plug>DnHLI
            \ <Esc>:call dn#md#insertHighlightLanguage(v:true)<CR>
if !hasmapto('<Plug>DnHLN')
    nmap <buffer> <unique> <LocalLeader>hl <Plug>DnHLN
endif
nmap <buffer> <unique> <Plug>DnHLN
            \ :call dn#md#insertHighlightLanguage()<CR>

" \fig - insert figure    {{{1

""
" Calls @function(dn#md#insertFigure) from |Insert-mode| and |Normal-mode| to
" insert a figure on the following line.
if !hasmapto('<Plug>DnFIGI')
    imap <buffer> <unique> <LocalLeader>fig <Plug>DnFIGI
endif
imap <buffer> <unique> <Plug>DnFIGI
            \ <Esc>:call dn#md#insertFigure(v:true)<CR>
if !hasmapto('<Plug>DnFIGN')
    nmap <buffer> <unique> <LocalLeader>fig <Plug>DnFIGN
endif
nmap <buffer> <unique> <Plug>DnFIGN
            \ :call dn#md#insertFigure()<CR>

" \pm  - convert yaml metadata block to use panzer    {{{1

""
" Calls @function(dn#md#panzerifyMetadata) from |Insert-mode| and
" |Normal-mode| to add a line to the document's metadata block for panzer
" styles.
if !hasmapto('<Plug>DnPMI')
    imap <buffer> <unique> <LocalLeader>pm <Plug>DnPMI
endif
imap <buffer> <unique> <Plug>DnPMI
            \ <Esc>:call dn#md#panzerifyMetadata(v:true)<CR>
if !hasmapto('<Plug>DnPMN')
    nmap <buffer> <unique> <LocalLeader>pm <Plug>DnPMN
endif
nmap <buffer> <unique> <Plug>DnPMN
            \ :call dn#md#panzerifyMetadata()<CR>
" }}}1

" Control statements    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :
