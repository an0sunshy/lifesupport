" http://zhranklin.com/react/article/571fbb0df248d8081601200e
" https://github.com/fatih/dotfiles/blob/master/vimrc

call plug#begin()
" completion/coding
"  Plug 'roxma/nvim-completion-manager' 
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
  Plug 'jiangmiao/auto-pairs' "自动括号匹配
  Plug 'scrooloose/nerdcommenter'
  Plug 'tpope/vim-surround'
  Plug 'junegunn/vim-easy-align'
  Plug 'scrooloose/nerdcommenter'
  Plug 'majutsushi/tagbar'

" Theme
  Plug 'mhartington/oceanic-next'
  Plug 'arcticicestudio/nord-vim'

" looking
  Plug 'Yggdroot/indentLine'
  Plug 'scrooloose/syntastic'
  Plug 'myusuf3/numbers.vim'
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
  Plug 'airblade/vim-gitgutter'
" Plug 'altercation/vim-colors-solarized'
  Plug 'plasticboy/vim-markdown'
  Plug 'mhinz/vim-startify'

" navigation
  Plug 'scrooloose/nerdtree'
  Plug 'ctrlpvim/ctrlp.vim'
  Plug 'majutsushi/tagbar'
  Plug 'rizzatti/dash.vim'

" Git 
  Plug 'tpope/vim-fugitive'
" Golang
  Plug 'fatih/vim-go'

" Json
  Plug 'elzr/vim-json', {'for' : 'json'}

" Docker
  Plug 'ekalinin/Dockerfile.vim', {'for' : 'Dockerfile'}

"Python
  Plug 'tell-k/vim-autopep8'

call plug#end()

" Or if you have Neovim >= 0.1.5
"if (has("termguicolors"))
syntax enable
set t_Co=256
set termguicolors
"endif

" Theme
 colorscheme OceanicNext
"

set path+=**
set laststatus=2
set encoding=utf-8              " Set default encoding to UTF-8
set autoread                    " Automatically reread changed files without asking me anything
set autoindent                  
set backspace=indent,eol,start  " Makes backspace key more powerful.
set incsearch                   " Shows the match while typing
set hlsearch                    " Highlight found searches
set mouse=a                     "Enable mouse modekk
set nocompatible
set noerrorbells             " No beep
set number                   " Show line numbers
set showcmd                  " Show me what I'm typing
set noswapfile               " Don't use swapfile
set nobackup                 " Don't create annoying backup files
set splitright               " Split vertical windows right to the current windows
set splitbelow               " Split horizontal windows below to the current windows
set autowrite                " Automatically save before :next, :make etc.
set hidden
set fileformats=unix,dos,mac " Prefer Unix over Windows over OS 9 formats
set noshowmatch              " Do not show matching brackets by flickering
set noshowmode               " We show the mode with airline or lightline
set ignorecase               " Search case insensitive...
set smartcase                " ... but not it begins with upper case 
set completeopt=menu,menuone
set nocursorcolumn 
set cursorline
set updatetime=300
set tabstop=4
set shiftwidth=4
set smartindent
set expandtab
set conceallevel=2

set clipboard^=unnamed
set clipboard^=unnamedplus


" fzf from Homebrew
set rtp+=/usr/local/opt/fzf

" Better split switching
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Easy Align
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" CtrlP
let g:ctrlp_cmd = 'CtrlPMRU'
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_switch_buffer = 'et'  " jump to a file if it's open already
let g:ctrlp_mruf_max=450    " number of recently opened files
let g:ctrlp_max_files=0     " do not limit the number of searchable files
let g:ctrlp_use_caching = 1
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_cache_dir = $HOME.'/.cache/ctrlp'
let g:ctrlp_match_window = 'bottom,order:btt,max:10,results:10'
let g:ctrlp_buftag_types = {'go' : '--language-force=go --golang-types=ftv'}

" NerdTree
" For toggling
noremap <Leader>n :NERDTreeToggle<cr>
noremap <Leader>f :NERDTreeFind<cr>

let NERDTreeShowHidden=1

" Vim-Go
let g:go_fmt_fail_silently = 0
let g:go_fmt_command = "goimports"
let g:go_list_type = "quickfix"
let g:go_auto_type_info = 0
let g:go_def_mode = "guru"
let g:go_echo_command_info = 1
let g:go_gocode_autobuild = 0
let g:go_gocode_unimported_packages = 1

let g:go_autodetect_gopath = 1
let g:go_info_mode = "guru"

" let g:go_metalinter_autosave = 1
" let g:go_metalinter_autosave_enabled = ['vet', 'golint']

let g:go_highlight_space_tab_error = 0
let g:go_highlight_array_whitespace_error = 0
let g:go_highlight_trailing_whitespace_error = 0
let g:go_highlight_extra_types = 0
let g:go_highlight_build_constraints = 1
let g:go_highlight_types = 0

let g:go_modifytags_transform = 'camelcase'

nmap <C-g> :GoDecls<cr>
imap <C-g> <esc>:<C-u>GoDecls<cr>

" run :GoBuild or :GoTestCompile based on the go file
function! s:build_go_files()
  let l:file = expand('%')
  if l:file =~# '^\f\+_test\.go$'
    call go#test#Test(0, 1)
  elseif l:file =~# '^\f\+\.go$'
    call go#cmd#Build(0)
  endif
endfunction

augroup go
  autocmd!

  autocmd FileType go nmap <silent> <Leader>v <Plug>(go-def-vertical)
  autocmd FileType go nmap <silent> <Leader>s <Plug>(go-def-split)

  autocmd FileType go nmap <silent> <Leader>x <Plug>(go-doc-vertical)

  autocmd FileType go nmap <silent> <Leader>i <Plug>(go-info)
  autocmd FileType go nmap <silent> <Leader>l <Plug>(go-metalinter)

  autocmd FileType go nmap <silent> <leader>b :<C-u>call <SID>build_go_files()<CR>
  autocmd FileType go nmap <silent> <leader>t  <Plug>(go-test)
  autocmd FileType go nmap <silent> <leader>r  <Plug>(go-run)
  autocmd FileType go nmap <silent> <leader>e  <Plug>(go-install)

  autocmd FileType go nmap <silent> <Leader>c <Plug>(go-coverage-toggle)

  " I like these more!
  autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')
  autocmd Filetype go command! -bang AV call go#alternate#Switch(<bang>0, 'vsplit')
  autocmd Filetype go command! -bang AS call go#alternate#Switch(<bang>0, 'split')
  autocmd Filetype go command! -bang AT call go#alternate#Switch(<bang>0, 'tabe')
augroup END

" Fugitive
vnoremap <leader>gb :Gblame<CR>
nnoremap <leader>gb :Gblame<CR>

" autopep8
let g:autopep8_disable_show_diff=1

" deoplete
let g:deoplete#enable_at_startup=1
let g:deoplete#enable_ignore_case=1 
" deoplete tab-complete
inoremap <expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"
