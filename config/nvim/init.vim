if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/plugged')

Plug 'dylanaraps/wal.vim'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
Plug 'jistr/vim-nerdtree-tabs'
Plug 'vim-syntastic/syntastic'
Plug 'jiangmiao/auto-pairs'

Plug 'mhinz/vim-startify'
Plug 'Valloric/YouCompleteMe', { 'do': './install.py --all' }

Plug 'tpope/vim-dispatch'

Plug 'lervag/vimtex'

Plug 'rhysd/vim-grammarous'

Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

Plug 'ctrlpvim/ctrlp.vim'

call plug#end()

colorscheme wal

syntax on

set scrolloff=3

set number

set clipboard=unnamedplus

set relativenumber

" latex
let g:syntastic_tex_checkers = []
let g:vimtex_view_method = 'zathura'

" mouse
set mouse=a

set linebreak
