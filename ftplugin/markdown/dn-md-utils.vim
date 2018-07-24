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

" Buffer variables    {{{1
" Filepath    {{{2
let b:dn_md_filepath = simplify(resolve(expand('%:p')))

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

" Mappings    {{{1

" \ab : add markdown boilerplate    {{{2
if !hasmapto('<Plug>DnABI')
    imap <buffer> <unique> <LocalLeader>ab <Plug>DnABI
endif
imap <buffer> <unique> <Plug>DnABI
            \ <Esc>:call dn#md_utils#addBoilerplate(g:dn_true)<CR>
if !hasmapto('<Plug>DnABN')
    nmap <buffer> <unique> <LocalLeader>ab <Plug>DnABN
endif
nmap <buffer> <unique> <Plug>DnABN
            \ :call dn#md_utils#addBoilerplate()<CR>

" \co : clean output    {{{2
if !hasmapto('<Plug>DnCOI')
    imap <buffer> <unique> <LocalLeader>co <Plug>DnCOI
endif
imap <buffer> <unique> <Plug>DnCOI
            \ <Esc>:call dn#md_utils#cleanOutput(
            \ {'caller': 'mapping', 'insert': g:dn_true})<CR>
if !hasmapto('<Plug>DnCON')
    nmap <buffer> <unique> <LocalLeader>co <Plug>DnCON
endif
nmap <buffer> <unique> <Plug>DnCON
            \ :call dn#md_utils#cleanOutput({'caller': 'mapping'})<CR>

" \fig : insert figure    {{{2
if !hasmapto('<Plug>DnFIGI')
    imap <buffer> <unique> <LocalLeader>fig <Plug>DnFIGI
endif
imap <buffer> <unique> <Plug>DnFIGI
            \ <Esc>:call dn#md_utils#insertFigure(g:dn_true)<CR>
if !hasmapto('<Plug>DnFIGN')
    nmap <buffer> <unique> <LocalLeader>fig <Plug>DnFIGN
endif
nmap <buffer> <unique> <Plug>DnFIGN
            \ :call dn#md_utils#insertFigure()<CR>

" \pm : convert yaml metadata block to use panzer    {{{2
if !hasmapto('<Plug>DnPMI')
    imap <buffer> <unique> <LocalLeader>pm <Plug>DnPMI
endif
imap <buffer> <unique> <Plug>DnPMI
            \ <Esc>:call dn#md_utils#panzerifyMetadata(g:dn_true)<CR>
if !hasmapto('<Plug>DnPMN')
    nmap <buffer> <unique> <LocalLeader>pm <Plug>DnPMN
endif
nmap <buffer> <unique> <Plug>DnPMN
            \ :call dn#md_utils#panzerifyMetadata()<CR>

" Commands    {{{1

" MUAddBoilerplate : add yaml metadata block and references boilerplate    {{{2
command! -buffer MUAddBoilerplate
            \ call dn#md_utils#addBoilerplate()

" MUCleanOutput : clean output    {{{2
command! -buffer MUCleanOutput
            \ call dn#md_utils#cleanOutput({'caller': 'command'})

" MUInsertFigure : insert figure    {{{2
command! -buffer MUInsertFigure
            \ call dn#md_utils#insertFigure()

" MUPanzerifyMetadata : convert yaml metadata block to use panzer    {{{2
command! -buffer MUPanzerifyMetadata
            \ call dn#md_utils#panzerifyMetadata()

" Autocommands    {{{1
" Clean output on exit    {{{2
augroup dn_markdown
    autocmd!
    autocmd BufDelete * call dn#md_utils#cleanOutput(
                \ {'caller': 'autocmd', 'caller_arg': expand('<afile>')})
augroup END

" Restore cpoptions    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo    " }}}1

" vim: set foldmethod=marker :
