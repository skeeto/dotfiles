" Mappings for working with this file.
map <Leader>ev :edit $MYVIMRC<CR>
map <Leader>es :source $MYVIMRC<CR>

filetype plugin indent on
syntax on

" Miscellaneous
set autoread
set backspace=indent,eol,start
set cpoptions+=$
set encoding=utf-8
set fileformat=unix
set formatoptions+=j
set guioptions=ac
set hidden
set incsearch
set lazyredraw
set listchars=eol:$,tab:>-
set nobackup
set nojoinspaces
set nostartofline
set noswapfile
set nrformats=hex
set shellslash
set showcmd
set ttimeoutlen=0
set tabstop=4

" Wildmenu
set wildmenu
set wildmode=longest,list
set path=**
set complete=.,w,b,u,t

" Fortran
let [fortran_do_enddo, fortran_free_source] = [1, 1]

" Colors and themes
if exists('&guicursor')
    set guicursor+=a:blinkon0
end
if &term =~ "256color" || &term =~ "xterm"
    let &t_SI = "\<Esc>[6 q"
    let &t_EI = "\<Esc>[2 q"
    if exists("&t_SR")
        let &t_SR = "\<Esc>[4 q"
    end
end
if has("x11")
    let &guifont="Noto Mono 11"
elseif has("gui_win32")
    let &guifont="Lucida Console:h11"
end

" Tab configuration
set expandtab
set shiftwidth=4
set smarttab
set autoindent

" No noise
set novisualbell
set noerrorbells
if exists('&belloff')
    set belloff=all
endif

" Statusline
set statusline=%m%F%=%y\ %l/%L\ %3v\ U+%04B
set laststatus=2
hi StatusLine guibg=Gray16 guifg=White

" netrw
let g:netrw_banner=0
let g:netrw_silent=1

" Set filetype for special cases
autocmd BufNewFile,BufRead .bash_local set filetype=sh

" Non-programming language files
autocmd FileType markdown,mail,text setlocal textwidth=74

" C style
set cinoptions+=t0  " don't indent function type
set cinoptions+=l1  " align with case label
set cinoptions+=:0  " align case with switch
set cinkeys-=0#     " directives aren't special
let c_no_curly_error=1  " Vim still lacks C99 support

" Go
autocmd FileType go setlocal makeprg=go\ build
autocmd FileType go setlocal noexpandtab shiftwidth=4 tabstop=4 textwidth=72
autocmd FileType go map <silent> <buffer> <leader>i
    \ :update \|
    \ :cexpr system("goimports -w " . expand('%')) \|
    \ :silent edit<cr>
autocmd FileType go
    \ map <buffer> [[ ?^\(func\\|var\\|type\\|import\\|package\)\><cr>
autocmd FileType go
    \ map <buffer> ]] /^\(func\\|var\\|type\\|import\\|package\)\><cr>

" Assembly style
autocmd FileType asm setlocal noexpandtab shiftwidth=8

" Makefile style
autocmd FileType make setlocal shiftwidth=8

" Build
set autowrite
if executable('make') && executable('nproc') && !(&shell =~ 'cmd.exe')
    set makeprg=make\ -kj$(nproc)
elseif executable('make')
    set makeprg=make\ -k
elseif executable('nmake')
    set makeprg=nmake\ -nologo
end

" Expand last search to all files with matching extension
map <Leader>/ :execute "vimgrep // **/*." . expand("%:e")<CR>

" Spelling
set spelllang=en_us
set spellfile=~/.vim/spell/en.utf-8.add

" Column stuff
hi ColorColumn ctermbg=darkgray guibg=darkgray
map <Leader>C :set colorcolumn=80<CR>
map <Leader>8 :set columns=80<CR>

" One sentence per line
map <Leader>w :nn j gj<CR>:nn k gk<CR>:se fo-=t<CR>:se lbr<CR>

" Extras
map <Leader>q :hi Error NONE<CR>
map <Leader>t :silent !ctags -R<CR><C-L>
map <Leader>c :%s/\s\+$//e<CR>
map <Leader>r :syntax sync fromstart<CR>

" Crypto (via Enchive)
map <Leader>pe :'<,'>!enchive archive \| base64<CR>
map <Leader>pd :'<,'>!base64 -d \| enchive --agent --pinentry extract<CR>

" Custom config for this machine
if filereadable(expand('~/.vimrc_local'))
    source ~/.vimrc_local
endif
