" Control statements    {{{1
set encoding=utf-8
scriptencoding utf-8

if exists('b:disable_dn_md_utils') && b:disable_dn_md_utils | finish | endif
if exists('b:loaded_dn_md_utils_commands') | finish | endif
let b:loaded_dn_md_utils_commands = 1

let s:save_cpo = &cpoptions
set cpoptions&vim
" }}}1

" Commands

" Mobify                  - create mobi file from epub output file    {{{1

""
" Calls @function(dn#md#generateMobi) to create a mobi output file from a
" previously output epub file.
command -buffer Mobify call dn#md#generateMobi()

" MUAddBoilerplate       - add metadata and references boilerplate    {{{1

""
" Calls @function(dn#md#addBoilerplate) to add a metadata header template,
" including title, author, date, and (panzer) styles, and a footer template
" for url reference links.
command -buffer MUAddBoilerplate call dn#md#addBoilerplate()

" MUChangeHighlightStyle - change highlight style cmdline arg    {{{1

""
" Calls @function(dn#md#changeHighlightStyle) to add, or change, the highlight
" style setting in |g:pandoc#compiler#arguments|.
command -buffer MUChangeHighlightStyle call dn#md#changeHighlightStyle()

" MUCleanOutput          - clean output    {{{1

""
" Calls @function(dn#md#cleanBuffer) to delete output files and temporary
" output directories. The user is not asked for confirmation before deletion.
command -buffer MUCleanOutput
            \ call dn#md#cleanBuffer({   'bufnr': bufnr('%'),
            \                         'say_none': v:true})

" MUInsertFigure         - insert figure    {{{1

""
" Calls @function(dn#md#insertFigure) to insert a figure on the following
" line.
command -buffer MUInsertFigure call dn#md#insertFigure()

" MUPanzerifyMetadata    - convert yaml metadata to use panzer    {{{1

""
" Calls @function(dn#md#panzerifyMetadata) to add a line to the document's
" metadata block for panzer styles.
command -buffer MUPanzerifyMetadata call dn#md#panzerifyMetadata()
" }}}1

" Control statements    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :
