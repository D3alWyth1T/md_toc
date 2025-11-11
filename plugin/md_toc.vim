" md_toc.vim - Vim plugin entry point for md_toc
" Maintainer: D3al
" License: MIT

" Prevent loading twice
if exists('g:loaded_md_toc')
  finish
endif
let g:loaded_md_toc = 1

" Save user's cpoptions
let s:save_cpo = &cpo
set cpo&vim

" Commands
command! MdTocGenerate lua require('md_toc').generate()
command! MdTocUpdate lua require('md_toc').update()
command! MdTocRemove lua require('md_toc').remove()
command! MdTocGoto lua require('md_toc').goto()
command! MdTocNav lua require('md_toc').navigate()

" Restore cpoptions
let &cpo = s:save_cpo
unlet s:save_cpo
