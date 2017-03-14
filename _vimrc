set encoding=utf-8
set backspace=indent,eol,start
set history=64
set guioptions=

" Search
set incsearch
set hlsearch
set ignorecase
set smartcase

" Colors
syntax on
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
set autoindent

" No noise
set novisualbell
set noerrorbells
if exists('&belloff')
   set belloff=all
endif

" Bindings
map B :buffer 
map <silent> [b :bp<cr>
map <silent> ]b :bn<cr>

" Statusline
set statusline=%m%n\ %F%=%l/%L\ %3v\ U+%04B
set laststatus=2
hi StatusLine guibg=Gray16 guifg=White

filetype plugin indent on
