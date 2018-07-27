" Boilerplate    {{{1
if exists('b:disable_dn_md_utils') && b:disable_dn_md_utils | finish | endif
if exists('s:loaded') | finish | endif
let s:loaded = 1

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
"   * calls @function(dn#md_util#addBoilerplate)
"
" <Leader>pm
"   * convert yaml metadata block to use panzer
"   * calls @function(dn#md_util#panzerifyMetadata)
"
" <Leader>fig
"   * insert figure on the following line
"   * calls @function(dn#md_util#insertFigure)
"
" <Leader>co
"   * clean output files and temporary directories
"   * calls @function(dn#md_util#cleanOutput)

" }}}1

" Mappings

" \ab  - add markdown boilerplate    {{{1

""
" Calls @function(dn#md_util#addBoilerplate) from |Insert-mode| and
" |Normal-mode| to add a metadata header template, including title, author,
" date, and (panzer) styles, and a footer template for url reference links.
if !hasmapto('<Plug>DnABI')
    imap <buffer> <unique> <LocalLeader>ab <Plug>DnABI
endif
imap <buffer> <unique> <Plug>DnABI
            \ <Esc>:call dn#md_util#addBoilerplate(g:dn_true)<CR>
if !hasmapto('<Plug>DnABN')
    nmap <buffer> <unique> <LocalLeader>ab <Plug>DnABN
endif
nmap <buffer> <unique> <Plug>DnABN
            \ :call dn#md_util#addBoilerplate()<CR>

" \co  - clean output    {{{1

""
" Calls @function(dn#md_util#cleanOutput) from |Insert-mode| and
" |Normal-mode| to delete output files and temporary output directories.
if !hasmapto('<Plug>DnCOI')
    imap <buffer> <unique> <LocalLeader>co <Plug>DnCOI
endif
imap <buffer> <unique> <Plug>DnCOI
            \ <Esc>:call dn#md_util#cleanOutput(
            \ {'caller': 'mapping', 'insert': g:dn_true})<CR>
if !hasmapto('<Plug>DnCON')
    nmap <buffer> <unique> <LocalLeader>co <Plug>DnCON
endif
nmap <buffer> <unique> <Plug>DnCON
            \ :call dn#md_util#cleanOutput({'caller': 'mapping'})<CR>

" \fig - insert figure    {{{1

""
" Calls @function(dn#md_util#insertFigure) from |Insert-mode| and
" |Normal-mode| to insert a figure on the following line.
if !hasmapto('<Plug>DnFIGI')
    imap <buffer> <unique> <LocalLeader>fig <Plug>DnFIGI
endif
imap <buffer> <unique> <Plug>DnFIGI
            \ <Esc>:call dn#md_util#insertFigure(g:dn_true)<CR>
if !hasmapto('<Plug>DnFIGN')
    nmap <buffer> <unique> <LocalLeader>fig <Plug>DnFIGN
endif
nmap <buffer> <unique> <Plug>DnFIGN
            \ :call dn#md_util#insertFigure()<CR>

" \pm  - convert yaml metadata block to use panzer    {{{1

""
" Calls @function(dn#md_util#panzerifyMetadata) from |Insert-mode| and
" |Normal-mode| to add a line to the document's metadata block for panzer
" styles.
if !hasmapto('<Plug>DnPMI')
    imap <buffer> <unique> <LocalLeader>pm <Plug>DnPMI
endif
imap <buffer> <unique> <Plug>DnPMI
            \ <Esc>:call dn#md_util#panzerifyMetadata(g:dn_true)<CR>
if !hasmapto('<Plug>DnPMN')
    nmap <buffer> <unique> <LocalLeader>pm <Plug>DnPMN
endif
nmap <buffer> <unique> <Plug>DnPMN
            \ :call dn#md_util#panzerifyMetadata()<CR>
" }}}1

" Boilerplate    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :
