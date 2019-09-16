syn on
set ai
set et
set ts=4
set sw=4
set sts=4
set bg=dark
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif
