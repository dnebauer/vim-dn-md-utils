" Boilerplate    {{{1
if exists('b:disable_dn_md_utils') && b:disable_dn_md_utils | finish | endif
if exists('s:loaded') | finish | endif
let s:loaded = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

" Documentation    {{{1
" - vimdoc does not automatically generate autocmds section

""
" @section Autocommands, autocmds
" This plugin is configured to automatically clean output files and
" directories associated with the current buffer when it is deleted (provided
" it is of markdown file type), and to automatically clean output files and
" directories associated with all markdown file buffers when vim exits. In all
" case the user is asked for confirmation before any files or directories are
" deleted.
"
" For more information on automatic cleaning see
" @function(dn#util#cleanBuffer).
"
" The autocmds responsible for this behaviour can be found in the
" "dn_markdown" autocmd group (see |autocmd-groups|) and can be viewed (see
" |autocmd-list|).
"
" Automatic cleaning on buffer and vim exit can be configured with
" |b:dn_md_no_autoclean|.

" }}}1

" Autocommands

" Clean output on buffer or vim exit    {{{1

""
" @setting b:dn_md_no_autoclean
" Prevents automatic deletion ("cleaning") of output artefacts when a buffer
" is deleted or vim exits. For more information see
" @function(dn#md#cleanBuffer), @function(dn#md#cleanAllBuffers), and
" @section(autocmds).

if !(exists('b:dn_md_no_autoclean') && b:dn_md_no_autoclean)
    augroup dn_markdown
        autocmd!
        autocmd BufDelete <buffer>
                    \ call dn#md#cleanBuffer({
                    \      'bufnr' : str2nr(expand('<abuf>')),
                    \     'confirm': v:true,
                    \   'pause_end': v:true})
        autocmd VimLeavePre *
                    \ debug call dn#md#cleanAllBuffers({  'confirm': v:true,
                    \                             'pause_end': v:true})
    augroup END
endif

" Boilerplate    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :
