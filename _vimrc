filetype plugin indent on
syntax on

set hid noswf ar aw bs=2 nosol lcs=eol:$,tab:>- pa=** cpt-=i ssl go=ac lz ttm=0
set enc=utf-8 ff=unix fo+=j nojs ai ts=4 et sw=4 nf=hex,unsigned is hls
set spl=en_us spf=~/.vim/spell/en.utf-8.add wmnu wim=longest,list
set stl=%m%F%=%y\ %l/%L\ %3v\ U+%04B ls=2 bo=all gcr=a:blinkon0
let g:netrw_banner = 0

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
    let $CFLAGS="-g3 -Wall -Wextra -Wdouble-promotion -Wno-unused-parameter
                \ -Wno-unused-function -Wno-unknown-pragmas
                \ -fsanitize=undefined -fsanitize-undefined-trap-on-error"
    let $LDFLAGS=" "
end
set mp=make\ -e\ 

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

autocmd FileType go setlocal mp=go\ build noet tw=72
autocmd FileType go map <silent> <buffer> <leader>i
    \ :update \|
    \ :cexpr system("goimports -w " . expand('%')) \|
    \ :silent edit<cr>
autocmd FileType go map <buffer> [[
    \ ?^\(func\\|var\\|type\\|import\\|package\)\><cr>
autocmd FileType go map <buffer> ]]
    \ /^\(func\\|var\\|type\\|import\\|package\)\><cr>

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
