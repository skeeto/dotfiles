filetype plugin indent on
syntax on

set hid ar aw bs=2 nosol lcs=eol:$,tab:>- is hls go=ac lz ttm=0 ls=2 cpo-=a
set bo=all gcr=a:blinkon0 wmnu wim=longest,list
set stl=%m%F%=%y\ %l/%L\ %3v\ U+%04B
set noswf pa=** cpt-=i ssl spl=en_us spf=~/.vim/spell/en.utf-8.add
set enc=utf-8 nofixeol ffs=unix,dos fo+=j/ nojs ai ts=4 et sw=4 nf=hex,unsigned
let g:netrw_banner=0

" Cursor shape in terminals like GUI
if &term =~ "256color" || &term =~ "xterm"
    let &t_SI = "\<Esc>[6 q"
    let &t_EI = "\<Esc>[2 q"
    if exists("&t_SR")
        let &t_SR = "\<Esc>[4 q"
    end
end

if $W64DEVKIT != ""
    set sh=sh shcf=-c sxq=\"
    let $CFLAGS="-g3 -DDEBUG -Wall -Wextra -Wdouble-promotion -Wconversion
                \ -Wno-sign-conversion -Wno-unused-parameter
                \ -Wno-unused-function -Wno-unknown-pragmas
                \ -fsanitize=undefined -fsanitize-trap"
    let $LDFLAGS="-nostartfiles"
end
set mp=make\ -e\ 
set efm^=%-G%f%l:\ note:%m

if has("x11")
    let &guifont="Monospace 11"
elseif has("gui_win32")
    let &guifont="Consolas:h11"
end

if !has("gui_running") && !has("win32")
    colorscheme ron
end

autocmd BufNewFile,BufRead .bash_local setlocal ft=sh
autocmd FileType markdown,mail,text setlocal tw=74

set cino=t0,l1,:0,L0 cink-=0#

autocmd FileType asm setlocal noet ts=8 sw=8

autocmd BufNewFile,BufRead go setlocal mp=go\ build noet tw=72
autocmd FileType go map <silent> <buffer> <leader>i
    \ :update \|
    \ :cexpr system("goimports -w " . expand('%')) \|
    \ :silent edit<cr>
autocmd FileType go map <buffer> [[
    \ ?^\(func\\|var\\|type\\|import\\|package\)\><cr>
autocmd FileType go map <buffer> ]]
    \ /^\(func\\|var\\|type\\|import\\|package\)\><cr>

let fortran_do_enddo=1
let fortran_indent_less=1
let fortran_more_precise=1
autocmd FileType fortran setlocal sw=2 ts=2

map <Leader>q :hi Error NONE<CR>
map <Leader>t :silent !ctags -R<CR><C-L>
map <Leader>c :%s/\s\+$//e<CR>
map <Leader>r :syntax sync fromstart<CR>
map <Leader>ev :edit $MYVIMRC<CR>
map <Leader>d :call system("debugbreak")<CR>

" Expand last search to all files with matching extension
map <Leader>/ :execute "vimgrep // **/*." . expand("%:e")<CR>

" Soft wrapping (for misdesigned Markdown dialects)
map <Leader>w :nn j gj<CR>:nn k gk<CR>:se fo-=t<CR>:se lbr<CR>

" Additional custom config for this machine
if filereadable(expand('~/.vimrc_local'))
    source ~/.vimrc_local
endif
