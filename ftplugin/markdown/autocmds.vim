" Boilerplate    {{{1
if exists('b:disable_dn_md_utils') && b:disable_dn_md_utils | finish | endif
if exists('s:loaded') | finish | endif
let s:loaded = 1

let s:save_cpo = &cpoptions
set cpoptions&vim
" }}}1

""
" @section Autocommands, autocmds
" Clean output files and directories when buffer deleted (if markdown file
" type) or vim exits (for all buffers of markdown file type). Involves
" autocmds for the |FileType|, |BufDelete| and |VimLeavePre| events. All
" autocmds created by this ftplugin are assigned to augroup "dn_markdown".

" Clean output on exit    {{{1

augroup dn_markdown
    autocmd!
    autocmd BufDelete * call dn#md_utils#cleanOutput(
                \ {'caller': 'autocmd', 'caller_arg': expand('<afile>')})
augroup END

" Boilerplate    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :
