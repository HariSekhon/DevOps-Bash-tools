"
"  Author: Hari Sekhon
"  Date: 2006-07-01 22:52:16 +0100 (Sat, 01 Jul 2006)
"

syn on

" ============================================================================ "

" show all settable option values and their values
"set all

set ai      " autoindent
set bg=dark " background
set et      " expandtab
set ic      " ignorecase
set is      " incsearch
"set list   " visually displays eol, tabs etc so you can always see them
set ls=1    " laststatus. Status line 0=off, 1=multi-windows, 2=on
set listchars=tab:>-,eol:$,trail:.,extends:# " changes the list characters, makes tabs appear as >---
set ml      " modeline.  respect the vim: stuff at the stop of files. This doesn't seem to work for me
set mls=15  " modelines. Controls how many lines to check for modeline, systems often set this to 0,
set nocp    " nocompatible
set nofen   "nofoldenable
set nohls   " nohlsearch
"set nu      " number (column on left)
set ru      " ruler
set sm      " showmatch. show matching brackets {}
set scs     " smartcase. switch to case sensitive match if uppercase letter is detected
set si      " smartindent
set smd     " showmode
set sta     " smarttab - make "tab" insert indents instead of tabs at beginning of line
set sts=4   " softtabstop. changes tab key to 4 spaces wide. This is the one you need
set sw=4    " shiftwidth. number of spaces for indentation, should be the same as tabstop really to make tabs and Shift-> the same width
set ts=4    " tabstop
set tw=0    " textwidth (stops auto wrapping)
set viminfo='100,<1000,s10,h " save <1000 lines in the registers instead of <50 lines between files since otherwise I lose lots of lines when deleting and pasting between files
set wrap    " line wrapping

" reload the buffer when file has changed but buffer has not (useful for go fmt from within vim)
set autoread

set encoding=utf-8      " The encoding displayed.
set fileencoding=utf-8  " The encoding written to file.

" add comment to next line when using 'o' in command mode
" add comment to next line when using Insert mode
set formatoptions+=or

" ============================================================================ "

"behave mswin
be xterm

:if has("gui_running")
    "colorscheme slate
    colo slate
:endif

" ============================================================================ "

filetype plugin indent on
filetype plugin on
"filetype off

" shows what last set ts, ie .vimrc
":verbose set ts

" set scrollbind - in each window then windows will scroll together

" ============================================================================ "

nmap ;l :echo "No linting defined for this filetype:" &filetype<CR>

if has("autocmd")
    " re-open at last cursor line and center screen on the cursor line
    "au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
    autocmd BufReadPost *
      \ if line ("'\"") > 0 && line ("'\"") <= line ("$") |
      \    exe "normal! g`\"" |
      \    exe "normal! g`\"zz" |
      \ endif

    " on write - auto-strip trailing whitespace on lines and remove trailing whitespace only lines end at of file
    autocmd BufWritePre * %s/\s\+$//e | %s#\($\n\s*\)\+\%$##e

    " highlight trailing whitespace
    " XXX: doesn't work
    "autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=red
    " this works - not using now we auto-strip trailing whitespace above on write anyway and it feels like this constant on/off highlighting slows things down and wastes energy
    "autocmd Filetype * match Error /\s\+$/

    au BufNewFile,BufRead Makefile set noet
    au BufNewFile,BufRead *Jenkinsfile* set filetype=groovy

    au BufNewFile,BufRead LICENSE set tw=80

    "au BufRead,BufNewFile perl set ts=4 st=4
    "au BufRead,BufNewFile *.pl set ts=4 st=4

    "au BufNew,BufRead *.pp set syntax=conf
    " filetype is better than syntax since it figures out indentation and tab completion etc and the ruby is better than conf since it gives more syntax highlighting
    au BufNew,BufRead *.pp set filetype=ruby sts=2 sw=2 ts=2

    au BufNew,BufRead *.yml set sts=2 sw=2 ts=2
    au BufNew,BufRead *.yaml set sts=2 sw=2 ts=2

    "au BufNew,BufRead *.rb set filetype=ruby sts=2 sw=2 ts=2

    " this will disable
    "au BufNew,BufRead *.txt set ft=
    au BufNew,BufRead *.txt hi def link confString  NONE

    augroup filetypedetect
        au! BufRead,BufNewFile *.hta setfiletype html
    augroup end

    " headtail.py is useful to see the top things to fix and the score on each run and can be found in the
    " https://github.com/HariSekhon/Python-DevOps-Tools repo which should be downloaded, run 'make' and add to $PATH
    au BufNew,BufRead *.py   nmap ;l :w<CR>:!clear; pylint "%" \| headtail.py<CR>
    au BufNew,BufRead *.pl   nmap ;l :w<CR>:!clear; perl -I . -tc "%"<CR>
    au BufNew,BufRead *.rb   nmap ;l :w<CR>:!clear; ruby -c "%"<CR>
    au BufNew,BufRead *.go   nmap ;l :w<CR>:!clear; go fmt "%"<CR><CR>

    au BufNew,BufRead .bash*,*.sh,*.ksh   nmap ;l :w<CR>:!clear; shellcheck -Calways "%" \| more -R<CR>

    " these tools are in the https://github.com/HariSekhon/Python-DevOps-Tools repo which should be downloaded, run 'make' and add to $PATH
    au BufNew,BufRead *.csv        nmap ;l :w<CR>:!clear; validate_csv.py "%"<CR>
    au BufNew,BufRead *.cson       nmap ;l :w<CR>:!clear; validate_cson.py "%"<CR>
    au BufNew,BufRead *.json       nmap ;l :w<CR>:!clear; validate_json.py "%"; echo; check_json.sh "%" \| more -R<CR>
    au BufNew,BufRead *.ini        nmap ;l :w<CR>:!clear; validate_ini.py "%"; validate_ini2.py "%"<CR>
    au BufNew,BufRead *.properties nmap ;l :w<CR>:!clear; validate_properties.py "%"<CR>
    au BufNew,BufRead *.ldif       nmap ;l :w<CR>:!clear; validate_ldap_ldif.py "%"<CR>
    au BufNew,BufRead *.md         nmap ;l :w<CR>:!clear; mdl "%" \| more -R<CR>
    au BufNew,BufRead *.scala      nmap ;l :w<CR>:!clear; scalastyle -c "$bash_tools/scalastyle_config.xml" "%" \| more -R<CR>
    au BufNew,BufRead *.toml       nmap ;l :w<CR>:!clear; validate_toml.py "%"<CR>
    au BufNew,BufRead *.xml        nmap ;l :w<CR>:!clear; validate_xml.py "%"<CR>
    au BufNew,BufRead *.yml,*.yaml nmap ;l :w<CR>:!clear; validate_yaml.py "%"<CR>

    " more specific matches like pom.xml need to come after less specific matches like *.xml as last statement wins
    au BufNew,BufRead *pom.xml*      nmap ;l :w<CR>:!clear; mvn validate -f "%" \| more -R<CR>
    " check_makefile.sh is in this repo which should be added to $PATH
    au BufNew,BufRead *Makefile*     nmap ;l :w<CR>:!clear; check_makefile.sh "%" \| more -R<CR>
    au BufNew,BufRead *build.gradle* nmap ;l :w<CR>:!clear; gradle -b "%" -m clean build \| more -R<CR> | nmap ;r :!gradle -b "%" clean build<CR>
    au BufNew,BufRead *build.sbt*    nmap ;l :w<CR>:!clear; cd "`dirname "%"`" && echo q \| sbt reload "%" \| more -R<CR>
    au BufNew,BufRead *.travis.yml*  nmap ;l :w<CR>:!clear; travis lint "%" \| more -R<CR>
    au BufNew,BufRead *Dockerfile*   nmap ;l :w<CR>:!clear; hadolint "%" \| more -R<CR>

endif

" ============================================================================ "

"nmap <silent> ;c :call Cformat()<CR>
nmap <silent> ;c :,!center.py<CR>
nmap <silent> ;e :,!center.py -s<CR>
nmap <silent> ;d :r !date '+\%F \%T \%z (\%a, \%d \%b \%Y)'<CR>kJ
nmap <silent> ;D :Done<CR>
nmap          ;f :,!fold -w 120 -s \| sed 's/[[:space:]]*$//'<CR>
"nmap <silent> ;h :call Hr()<CR>
nmap <silent> ;h :Hr<CR>
" this inserts Hr literally
"imap <silent> <C-H> :Hr<CR>
nmap <silent> ;j :JHr<CR>
"nmap <silent> ;' :call Sq()<CR>
" done automatically on write now
"nmap <silent> ;' :call StripTrailingWhiteSpace()<CR>
nmap <silent> ;' :w<CR> :!clear; git diff "%"<CR>
nmap          ;n :n<CR>
nmap          ;p :prev<CR>
nmap          ;q :q<CR>
nmap          ;r :call WriteRun()<CR>
"nmap <silent> ;s :call ToggleSyntax()<CR>
nmap <silent> ;s :,!sqlcase.pl<CR>
"nmap          ;u :call HgGitU()<CR>
"nmap          ;; :call HgGitU()<CR>
" command not found
"nmap          ;; :! . ~/.bashrc; gitu "%"<CR>
nmap          ;; :w<CR> :! bash -ic 'gitu "%"'<CR>
nmap          ;g :! bash -ic 'cd $(dirname "%") && git status'<CR>
nmap          ;G :! bash -ic 'cd $(dirname "%") && git log -p'<CR>
nmap          ;. :! bash -ic 'cd $(dirname "%") && push'<CR>
nmap          ;v :source ~/.vimrc<CR>
nmap          ;w :w<CR>
"nmap          ;x :x<CR>

" ============================================================================ "

function! ToggleSyntax()
    if exists("g:syntax_on")
        syntax off
    else
        syntax enable
    endif
endfunction

":command Hr  :normal i # ============================================================================ #<ESC>lx
:command! Hr  :normal a# <ESC>76a=<ESC>a #<ESC>
":function Hr()
    ":s/^/# ============================================================================ #/
    "if b:current_syntax eq "sql"
    "    ::normal a-- <ESC>74a=<ESC>a --<ESC>
    "else
        ":normal a# <ESC>76a=<ESC>a #<ESC>
    "endif
":endfunction

":function Br()
":call Hr()
":endfunction
:command! Br :Hr

"function JHr()
"    s,^,// ========================================================================== //,
"endfunction
":command JHr :normal a// ========================================================================== //<ESC>lx
:command! JHr :normal a// <ESC>74a=<ESC>a //<ESC>

:command! Done :normal 37a=<ESC>a DONE <ESC>37a=<ESC>

":function RemoveIPs()
"    : %s/\d\+\.\d\+\.\d\+\.\d\+/<IP_REMOVED>/gc
":endfunction
"
":function RemoveMacs()
"    : %s/\w\w:\w\w:\w\w:\w\w:\w\w:\w\w/<MAC_REMOVED>/gc
":endfunction
"
":function RemoveDomains()
"    : %s/company1/<DOMAIN_REMOVED>/gci
"    : %s/company2/<DOMAIN_REMOVED>/gci
":endfunction

function! Scrub()
    ": call RemoveIPs()
    ": call RemoveMacs()
    ": call RemoveDomains()
    :%!anonymize.py --all
endfunction

" StripQuotes()
function! Sq()
    :s/["']//g
endfunction

function! StripTrailingWhiteSpace()
    :%s/[[:space:]]*$//
endfunction

function! WriteRun()
    :w
    :!./%
    " TODO: if .go then 'go run %'
endfunction

" ============================================================================ "

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
