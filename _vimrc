" Mappings for working with this file.
map <Leader>ev :edit ~/.vimrc<CR>
map <Leader>es :source ~/.vimrc<CR>

" Miscellaneous
set encoding=utf-8
set backspace=indent,eol,start
set guioptions=
set autochdir
set hidden
set cpoptions+=$
set lazyredraw
set wildmenu
set autowrite

" One space between sentences please.
set nojoinspaces

" Never use backslashes for paths.
set shellslash

" Search
set incsearch
set hlsearch
set ignorecase
set smartcase

" Colors and themes
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

" Statusline
set statusline=%m%F%=%y\ %l/%L\ %3v\ U+%04B
set laststatus=2
hi StatusLine guibg=Gray16 guifg=White

" netrw
let g:netrw_banner=0

" Filetypes
filetype on
filetype plugin on
filetype indent on

" Build
set makeprg=smake

" Spelling
set spelllang=en_us
set spellfile=~/.vim/en.utf-8.add
