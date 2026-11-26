" Vundle
set nocompatible              " be iMproved, required
filetype off                  " required

set number
set showmatch
" filetype indent on
set smartindent shiftwidth=4
set autoindent
set expandtab
set smarttab
autocmd FileType make setlocal noexpandtab
autocmd FileType make setlocal nosmarttab
set nowrap
set incsearch
set wildmode=list:longest
syntax enable

set modeline

autocmd FileType markdown nnoremap <buffer> <leader>p :w<CR>:vert term glow -p %<CR>
