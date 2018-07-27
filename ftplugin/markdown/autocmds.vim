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
" Clean output files and directories when buffer deleted (if markdown file
" type) or vim exits (for all buffers of markdown file type). Involves
" autocmds for the |FileType|, |BufDelete| and |VimLeavePre| events. All
" autocmds created by this ftplugin are assigned to augroup "dn_markdown".

" }}}1

" Autocommands

" Clean output on exit    {{{1
augroup dn_markdown
    autocmd!
    autocmd FileType * call dn#md_util#_register(
                \ simplify(resolve(expand('<afile>:p'))),
                \ '<amatch>'
                \ )
    autocmd BufDelete * call dn#md_util#cleanOutput(
                \ {'caller': 'autocmd', 'caller_arg': expand('<afile>')})
augroup END

" Boilerplate    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :
