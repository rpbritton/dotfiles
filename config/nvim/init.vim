"if empty(glob('~/.config/nvim/autoload/"use.vim'))
"  silent !curl -fLo ~/.config/nvim/autoload/"use.vim --create-dirs
"    \ https://raw.github"usercontent.com/junegunn/vim-"use/master/"use.vim
"  autocmd VimEnter * "useInstall --sync | source $MYVIMRC
"endif
"
"call "use#begin('~/.config/nvim/"useged')
"
""use 'dylanaraps/wal.vim'
"
""use 'vim-airline/vim-airline'
""use 'vim-airline/vim-airline-themes'
"
""use 'scrooloose/nerdcommenter'
""use 'scrooloose/nerdtree'
""use 'jistr/vim-nerdtree-tabs'
""use 'vim-syntastic/syntastic'
""use 'jiangmiao/auto-pairs'
"
""use 'mhinz/vim-startify'
""use 'Valloric/YouCompleteMe', { 'do': './install.py --all' }
"
""use 'tpope/vim-dispatch'
"
""use 'lervag/vimtex'
"
""use 'rhysd/vim-grammarous'
"
""use 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
"
""use 'ctrlpvim/ctrlp.vim'
"
""use 'mcchrish/zenbones.nvim', { 'branch': 'main' }
""use 'rktjmp/lush.nvim'
""use 'rktjmp/shipwright.nvim'
"
"call "use#end()
"
"colorscheme wal
"
"syntax on
"
"set scrolloff=3
"
"set number
"
"set clipboard=unnamedplus
"
"set relativenumber
"
"" latex
"let g:syntastic_tex_checkers = []
"let g:vimtex_view_method = 'zathura'
"
"" mo"use
"set mo"use=a
"
"set linebreak

lua require('plugins')
