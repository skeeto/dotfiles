filetype plugin indent on
syntax on

set hid ar aw bs=2 go=ac is lz nosol nf=hex lcs=eol:$,tab:>- ttm=0 noswf
set enc=utf-8 ff=unix fo+=j nojs ts=4 et sw=4 pa=** cpt-=i ssl
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
end
if &sh !~ "cmd.exe"
    set mp=make\ -kj$(nproc)
end

if has("x11")
    let &guifont="Monospace 11"
elseif has("gui_win32")
    let &guifont="Lucida Console:h11"
end

autocmd BufNewFile,BufRead .bash_local setlocal ft=sh
autocmd FileType markdown,mail,text setlocal tw=74

set cino=t0,l1,:0 cink-=0#

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

" Expand last search to all files with matching extension
map <Leader>/ :execute "vimgrep // **/*." . expand("%:e")<CR>

" Soft wrapping (for misdesigned Markdown dialects)
map <Leader>w :nn j gj<CR>:nn k gk<CR>:se fo-=t<CR>:se lbr<CR>

" Additional custom config for this machine
if filereadable(expand('~/.vimrc_local'))
    source ~/.vimrc_local
endif
