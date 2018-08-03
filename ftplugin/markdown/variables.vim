" Control statements    {{{1
set encoding=utf-8
scriptencoding utf-8
if exists('b:disable_dn_md_utils') && b:disable_dn_md_utils | finish | endif
if exists('s:loaded') | finish | endif
let s:loaded = 1

let s:save_cpo = &cpoptions
set cpoptions&vim
" }}}1

""
" @section Variables, vars
" This ftplugin contributes to the |dn-utils| plugin's help system (see
" |dn#util#help()| for details). In the help system navigate to:
" vim -> markdown ftplugin.

" Filepath    {{{1
let b:dn_md_filepath = simplify(resolve(expand('%:p')))

" System help    {{{1
if !exists('g:dn_help_plugins')
    let g:dn_help_plugins = []
endif
if !exists('g:dn_help_topics')
    let g:dn_help_topics = {}
endif
if !exists('g:dn_help_data')
    let g:dn_help_data = {}
endif
if count(g:dn_help_plugins, 'dn-md-utils') == 0
    call add(g:dn_help_plugins, 'dn-md-utils')
    if !has_key(g:dn_help_topics, 'markdown utils ftplugin')
        let g:dn_help_topics['markdown utils ftplugin'] = {}
    endif
    let g:dn_help_topics['markdown utils ftplugin']['refs']
                \ = 'markdown_utils_refs'
    let g:dn_help_data['markdown_utils_refs'] = [
        \ 'Format for equations (Eq), figures (Fig), tables (Tbl):',
        \ '',
        \ '',
        \ '',
        \ 'Eq:  $$ y = mx + b $$ {#eq:id}',
        \ '',
        \ '',
        \ '',
        \ '     See @eq:id or {@eq:id}.',
        \ '',
        \ '',
        \ '',
        \ 'Fig: ![Caption.][imageref]',
        \ '',
        \ '',
        \ '',
        \ '     See @fig:id or {@fig:id}.',
        \ '',
        \ '',
        \ '',
        \ '        [imageref]: image.png "Alt text" {#fig:id}',
        \ '',
        \ '',
        \ '',
        \ 'Tbl: A B',
        \ '',
        \ '     - -',
        \ '',
        \ '     0 1',
        \ '',
        \ '',
        \ '',
        \ '     Table: Caption. {#tbl:id}',
        \ '',
        \ '',
        \ '',
        \ '     See @tbl:id or {@tbl:id}.',
        \ ]
    let g:dn_help_topics['markdown utils ftplugin']['utilities']
                \ = 'markdown_utils_util'
    let g:dn_help_data['markdown_utils_util'] = [
        \ 'This markdown ftplugin has the following utility features:',
        \ '',
        \ '',
        \ '',
        \ 'Feature                     Mapping  Command',
        \ '',
        \ '--------------------------  -------  -----------------',
        \ '',
        \ 'add metadata boilerplate    \ab      MUAddBoilerplate',
        \ '',
        \ 'clean output                \co      MUCleanOutput',
        \ '',
        \ 'insert figure               \fig     MUInsertFigure',
        \ '',
        \ 'convert metadata to panzer  \pm      MUPanzerifyMetadata',
        \ ]
endif
" }}}1

" Control statements    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :
