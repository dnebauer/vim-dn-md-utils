" Boilerplate    {{{1
if exists('b:disable_dn_md_utils') && b:disable_dn_md_utils | finish | endif
if exists('s:loaded') | finish | endif
let s:loaded = 1

let s:save_cpo = &cpoptions
set cpoptions&vim
" }}}1

" Commands

" MUAddBoilerplate    - add metadata and references boilerplate    {{{1

""
" Calls @function(dn#md_util#addBoilerplate) to add a metadata header
" template, including title, author, date, and (panzer) styles, and a footer
" template for url reference links.
command -buffer MUAddBoilerplate call dn#md_util#addBoilerplate()

" MUCleanOutput       - clean output    {{{1

""
" Calls @function(dn#md_util#cleanBuffer) to delete output files and
" temporary output directories. The user is not asked for confirmation before
" deletion.
command -buffer MUCleanOutput call dn#md_util#cleanBuffer(bufnr('%'), 0, 0)

" MUInsertFigure      - insert figure    {{{1

""
" Calls @function(dn#md_util#insertFigure) to insert a figure on the
" following line.
command -buffer MUInsertFigure call dn#md_util#insertFigure()

" MUPanzerifyMetadata - convert yaml metadata block to use panzer    {{{1

""
" Calls @function(dn#md_util#panzerifyMetadata) to add a line to the
" document's metadata block for panzer styles.
command -buffer MUPanzerifyMetadata call dn#md_util#panzerifyMetadata()
" }}}1

" Boilerplate    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :
