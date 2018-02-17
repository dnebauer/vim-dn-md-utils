" Function:    Vim ftplugin for markdown
" Last Change: 2018-02-03
" Maintainer:  David Nebauer <david@nebauer.org>

" Load only once    {{{1
if exists('b:did_dnm_md_utils') | finish | endif
let b:did_dnm_md_utils = 1

" Save cpoptions    {{{1
" - avoids unpleasantness from customised 'compatible' settings
let s:save_cpo = &cpoptions
set cpoptions&vim

" Add system help    {{{1
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
        \ '------------------------    -------  -----------------',
        \ '',
        \ 'convert metadata to panzer  \pm      MUMetadata',
        \ ]
endif

" Mappings    {{{1

" \pm : convert yaml metadata block to use panzer    {{{2
if !hasmapto('<Plug>DnPMI')
    imap <buffer> <unique> <LocalLeader>pm <Plug>DnPMI
endif
imap <buffer> <unique> <Plug>DnPMI
            \ <Esc>:call dn#md_utils#panzerMetadata(g:dn_true)<CR>
if !hasmapto('<Plug>DnPMN')
    nmap <buffer> <unique> <LocalLeader>pm <Plug>DnPMN
endif
nmap <buffer> <unique> <Plug>DnPMN
            \ :call dn#md_utils#panzerMetadata()<CR>

" \mb : add markdown boilerplate    {{{2
if !hasmapto('<Plug>DnMBI')
    imap <buffer> <unique> <LocalLeader>mb <Plug>DnMBI
endif
imap <buffer> <unique> <Plug>DnMBI
            \ <Esc>:call dn#md_utils#panzerify(g:dn_true)<CR>
if !hasmapto('<Plug>DnMBN')
    nmap <buffer> <unique> <LocalLeader>mb <Plug>DnMBN
endif
nmap <buffer> <unique> <Plug>DnMBN
            \ :call dn#md_utils#panzerify()<CR>

" Commands    {{{1

" MUMetadata : convert yaml metadata block to use panzer    {{{2
command! -buffer MUMetadata
            \ call dn#md_utils#panzerMetadata()

" Restore cpoptions    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo                                                         " }}}1

" vim: set foldmethod=marker :
