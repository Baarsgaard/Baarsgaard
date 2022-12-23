syntax enable
let g:sh_fold_enabled=5
let g:is_sh=1
set filetype=on
set foldmethod=syntax
set foldlevel=1
" foldnestmax=1 
set modeline
set modelines=5

augroup yaml_fix
    autocmd!
    autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab indentkeys-=0# indentkeys-=<:>
augroup END

set noswapfile
nnoremap <c-q> <c-v>

" WSL yank support
let s:clip = 'clip.exe'
if executable(s:clip)
    augroup WSLYank
        autocmd!
        autocmd TextYankPost * if v:event.operator ==# 'y' | call system(s:clip, @0) | endif
    augroup END
endif
