syn on
set ai
set et
set ts=4
set sw=4
set sts=4
set bg=dark
" add comment to next line when using 'o' in command mode
" add comment to next line when using Insert mode
set formatoptions+=or

" re-open at last cursor line
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

  " auto-strip trailing whitespace on write
  autocmd BufWritePre * %s/\s\+$//e
endif

" either works, requires expand()
"let MYLOCALVIMRC = "~/.vimrc.local"
"let MYLOCALVIMRC = "$HOME/.vimrc.local"

" Function to source only if file exists {
function! SourceIfExists(file)
  if filereadable(expand(a:file))
    exe 'source' a:file
  endif
endfunction
" }

call SourceIfExists("~/.vimrc.local")
call SourceIfExists("~/.vim/colors.vim")

if has('gui_running')
  call SourceIfExists("~/.gvimrc.local")
endif
