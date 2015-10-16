" -*- default-directory: "~/.dotfiles"; -*-

set nocompatible
set encoding=utf-8
set backspace=indent,eol,start
set nobackup
set noswapfile
set history=100
set undolevels=100
set ruler
set showcmd
set autoindent
set hidden
set modelines=0
set autochdir
set guioptions=
set viminfo="NONE"

" Search
set incsearch
set hlsearch
set ignorecase
set smartcase

" Colors
syntax on
set t_Co=256
colorscheme desert
set background=dark

" Show trailing whitespace
set list
set listchars=tab:>-,trail:░,extends:#,nbsp:.

" Tab configuration
set expandtab
set shiftwidth=4
set shiftround
set smarttab

" No noise
set visualbell
set noerrorbells

" Bindings
map Q gq
map B :buffer 
map <silent> [b :bp<cr>
map <silent> ]b :bn<cr>

filetype plugin indent on
autocmd FileType text setlocal textwidth=72

if has('mouse')
  set mouse=a
endif
