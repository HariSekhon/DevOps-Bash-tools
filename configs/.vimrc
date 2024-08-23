"
"  Author: Hari Sekhon
"  Date: 2006-07-01 22:52:16 +0100 (Sat, 01 Jul 2006)
"
"  vim:ts=4:sts=4:sw=4:tw=0:et
"

" ============================================================================ "
"                                   v i m r c
" ============================================================================ "

" to reload without restarting vim
"
" :source ~/.vimrc

" if you cursor location and copy/paste register buffers are not saving
" then ensure that your ~/.viminfo file is owned by your user:
"
"   sudo chown "$USER" ~/.viminfo

syn on

highlight StatusLine ctermfg=yellow ctermbg=darkgray
highlight StatusLineNC ctermfg=darkgrey ctermbg=yellow
highlight VertSplit ctermfg=darkgrey ctermbg=yellow

set visualbell

" ============================================================================ "
"                               S e t   C o n f i g
" ============================================================================ "

" show all settable option values and their values
"set all

set ai      " autoindent
set backspace=indent,eol,start " fixes not being able to backspace not typed during current insert mode session
set bg=dark " background
set et      " expandtab
set ic      " ignorecase
set is      " incsearch
"set list   " visually displays eol, tabs etc so you can always see them
set ls=1    " laststatus - Status line 0=off, 1=multi-windows, 2=on
set listchars=tab:>-,eol:$,trail:.,extends:# " changes the list characters, makes tabs appear as >---
set ml      " modeline - respect the vim: stuff at the stop of files, often off for root
set mls=15  " modelines - Controls how many lines to check for modeline, systems often set this to 0
set nocp    " nocompatible
set nofen   " nofoldenable
set nohls   " nohlsearch
set nojs    " nojoinspaces - only use 1 space even when J joining lines even when line ends in a special char
"set nu      " number (column on left)
set ru      " ruler
set sm      " showmatch. show matching brackets {}
set scs     " smartcase. switch to case sensitive match if uppercase letter is detected
set si      " smartindent
set smd     " showmode
" enabling either one of these causes deleting 4 spaces with each backspace, often over deletes when writing yaml / docs
set sta     " smarttab - make 'tab' insert indents instead of tabs at beginning of line
set sts=4   " softtabstop
set sw=4    " shiftwidth - number of spaces for indentation, should be the same as tabstop really to make tabs and Shift-> the same width
set ts=4    " tabstop
set tw=0    " textwidth (stops auto wrapping)
set viminfo='100,<1000,s10,h " save <1000 lines in the registers instead of <50 lines between files since otherwise I lose lots of lines when deleting and pasting between files
set wrap    " line wrapping

" reload the buffer when file has changed but buffer has not (useful for 'go fmt' / 'git pull' hotkeys from within vim)
set autoread

" write buffer on next / prev etc
set autowrite

set encoding=utf-8      " The encoding displayed.
set fileencoding=utf-8  " The encoding written to file.

" add comment to next line when using 'o' in command mode
" add comment to next line when using Insert mode
set formatoptions+=or


" ============================================================================ "
"                                   G U I
" ============================================================================ "

" see also ~/.gvimrc.local sourcing at bottom of this config

"behave mswin
be xterm

:if has("gui_running")
    "colorscheme slate
    colo slate
:endif


" ============================================================================ "
"                               P l u g i n s
" ============================================================================ "

filetype plugin on
filetype plugin indent on
"filetype off

" shows what last set ts, ie .vimrc
":verbose set ts

" set scrollbind - in each window then windows will scroll together

" =======
" Vundle
"
" to install plugins do:
"
" :PluginInstall

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'airblade/vim-gitgutter'
"Plugin 'fatih/vim-go'
Plugin 'hashivim/vim-consul'
"Plugin 'hashivim/vim-nomadproject'
"Plugin 'hashivim/vim-ottoproject'
Plugin 'hashivim/vim-packer'
Plugin 'hashivim/vim-terraform'
Plugin 'hashivim/vim-vagrant'
"Plugin 'hashivim/vim-vaultproject'
Plugin 'vim-syntastic/syntastic'
"Plugin 'dense-analysis/ale'
Plugin 'juliosueiras/vim-terraform-completion'
" gets in the way editing more than it helps because it adds doubles of quotes
" and braces that often break edits or require more keystrokes to remove than saved
"Plugin 'jiangmiao/auto-pairs'
Plugin 'preservim/nerdcommenter'
Plugin 'terrastruct/d2-vim'
"Plugin 'tpope/vim-commentary'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-surround'
Plugin 'tmux-plugins/vim-tmux'

" comment at start of line instead of code indentation level
" doesn't work: https://github.com/preservim/nerdcommenter/issues/467
let g:NERDDefaultAlign = 'left'
let g:NERDCommentEmptyLines = 1

let g:gitgutter_enabled = 0
" keep setting if reloading, otherwise default to 1 for enabled
"let g:pluginname_setting = get(g:, 'gitgutter_enabled', 1)

" align settings automatically with Tabularize
let g:terraform_align=1
let g:terraform_fold_sections=0
" auto format *.tf /*.tfvars with 'terraform fmt' or manually calling :TerraformFmt
let g:terraform_fmt_on_save=1

" Syntastic Config
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*

"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0

" (Optional) Enable terraform plan to be include in filter
"let g:syntastic_terraform_tffilter_plan = 1

call vundle#end()


" ============================================================================ "
"                               A u t o c m d
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

    " writes a vim script that saves and restore folds, ts/sts/sw options etc
    "autocmd BufWinLeave *.* mkview
    "autocmd BufWinEnter *.* silent loadview

    " doubles up with nmap ;l
    "au BufWritePost *.tf,*.tfvars :!clear; cd "%:p:h" && terraform fmt -diff; terraform validate

    " highlight trailing whitespace
    " XXX: doesn't work
    "autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=red
    " this works - not using now we auto-strip trailing whitespace above on write anyway and it feels like this constant on/off highlighting slows things down and wastes energy
    "autocmd Filetype * match Error /\s\+$/

    au BufNewFile,BufRead Makefile set noet
    au BufNewFile,BufRead *.md set ts=2 sw=2 sts=2 et
    au BufNewFile,BufRead *Jenkinsfile* set filetype=groovy ts=2 sw=2 sts=2 et

    au BufNewFile,BufRead LICENSE set tw=80

    au BufRead,BufNewFile perl set ts=4 sts=4 et
    au BufRead,BufNewFile *.pl set ts=4 sts=4 et

    "au BufNew,BufRead *.pp set syntax=conf
    " filetype is better than syntax since it figures out indentation and tab completion etc and the ruby is better than conf since it gives more syntax highlighting
    au BufNew,BufRead *.pp set filetype=ruby sts=2 sw=2 ts=2 et

    au BufNew,BufRead     *.tf  set filetype=terraform sts=2 sw=2 ts=2 et
    au BufNewFile,BufRead *.hcl set filetype=terraform sts=2 sw=2 ts=2 et

    au BufNew,BufRead *.yml set sts=2 sw=2 ts=2 et
    au BufNew,BufRead *.yaml set sts=2 sw=2 ts=2 et

    au BufNew,BufRead *.groovy,*.gvy,*.gy,*.gsh set filetype=groovy
    au BufNew,BufRead *.jsh set filetype=java

    "au BufNew,BufRead *.rb set filetype=ruby sts=2 sw=2 ts=2

    " this will disable
    "au BufNew,BufRead *.txt set ft=
    au BufNew,BufRead *.txt hi def link confString  NONE

    augroup filetypedetect
        au! BufRead,BufNewFile *.hta setfiletype html
    augroup end

"    autocmd FileType c,cpp,java,scala let b:comment_char = '//'
"    autocmd FileType sh,perl,python   let b:comment_char = '#'
"    autocmd FileType ruby             let b:comment_char = '#'
"    autocmd FileType conf,dockerfile,fstab let b:comment_char = '#'
"    autocmd FileType sql              let b:comment_char = '--'
"    autocmd FileType tex              let b:comment_char = '%'
"    autocmd FileType mail             let b:comment_char = '>'
"    autocmd FileType vim              let b:comment_char = '"'

    " headtail.py is useful to see the top things to fix and the score on each run and can be found in the
    " https://github.com/HariSekhon/Python-DevOps-Tools repo which should be downloaded, run 'make' and add to $PATH
    au BufNew,BufRead *.py   nmap ;l :w<CR>:!clear; pylint "%" \| headtail.py<CR>
    au BufNew,BufRead *.pl   nmap ;l :w<CR>:!clear; perl -I . -tc "%"<CR>
    au BufNew,BufRead *.rb   nmap ;l :w<CR>:!clear; ruby -c "%"<CR>
    " :e reloads the file because autoread isn't working after gofmt in this case
    au BufNew,BufRead *.go   nmap ;l :w<CR> :!gofmt -w "%" && go build "%"<CR>
    " breaks waiting to see go build error
    " :e<CR>

    " to make vim autoread after gofmt
    " doesn't seem to work, using explicit :e now
    "au CursorHold * checktime
    "au CursorHold,CursorHoldI * checktime
    "au FocusGained,BufEnter * :checktime

    " TODO: any better groovy/java CLI linters
    au BufNew,BufRead *.groovy,*.gvy,*.gy,*.gsh  nmap ;l :w<CR>:!groovyc "%"; rm -f -- "%:p:h"/*.class <CR>

    " TODO: often these don't trigger on window switching between different file types

    " %:t = basename of file
    au BufNew,BufRead .bash*,*.sh,*.ksh   nmap ;l :w<CR>:!clear; cd "%:p:h" && shellcheck -x -Calways "%:t" \| more -R<CR>
    " for scripts that don't end in .sh like Google Cloud Shell's .customize_environment
    au FileType sh                        nmap ;l :w<CR>:!clear; cd "%:p:h" && shellcheck -x -Calways "%:t" \| more -R<CR>

    au BufNewFile,BufRead .vimrc    nmap ;l :w<CR> :!clear<CR> :call LintVimrc() <CR>

    " these tools are in the https://github.com/HariSekhon/DevOps-Python-tools & DevOps-Bash-tools repos which should be downloaded, run 'make' and add to $PATH
    au BufNew,BufRead *.csv        nmap ;l :w<CR>:!clear; validate_csv.py "%"<CR>
    au BufNew,BufRead *.cson       nmap ;l :w<CR>:!clear; validate_cson.py "%"<CR>
    au BufNew,BufRead *.d2         nmap ;l :w<CR>:!clear; d2 fmt "%" <CR> :edit <CR> :1s/^# \!\//#\!\// <CR>
    au BufNew,BufRead *.json       nmap ;l :w<CR>:!clear; validate_json.py "%"; echo; check_json.sh "%" \| more -R<CR>
    au BufNew,BufRead *.ini        nmap ;l :w<CR>:!clear; validate_ini.py "%"; validate_ini2.py "%"<CR>
    " doesn't work on ansible inventory anyway
    "au FileType       ini          nmap ;l :w<CR>:!clear; validate_ini.py "%"; validate_ini2.py "%"<CR>
    au BufNew,BufRead *.php        nmap ;l :w<CR>:!clear; php5 -l "%"<CR>
    " this acts as both a validation as well as a fast way of being able to edit the plist
    " trying to convert to json results in an error "invalid object in plist for destination format"
    au BufNew,BufRead *.plist      nmap ;l :w<CR>:!clear; plutil -convert xml1 "%" && echo PList OK<CR>
    au BufNew,BufRead *.properties nmap ;l :w<CR>:!clear; validate_properties.py "%"<CR>
    au BufNew,BufRead *.ldif       nmap ;l :w<CR>:!clear; validate_ldap_ldif.py "%"<CR>
    au BufNew,BufRead *.md         nmap ;l :w<CR>:!clear; mdl "%" \| more -R<CR>
    "au BufNew,BufRead *.sql        nmap ;l :w<CR>:!clear; TODO "%" \| more -R<CR>
    au BufNew,BufRead *.scala      nmap ;l :w<CR>:!clear; scalastyle -c "$bash_tools/scalastyle_config.xml" "%" \| more -R<CR>
    au BufNew,BufRead *.toml       nmap ;l :w<CR>:!clear; validate_toml.py "%"<CR>
    au BufNew,BufRead *.xml        nmap ;l :w<CR>:!clear; validate_xml.py "%"<CR>
    " TODO: needs fix to allow multiple inline yaml docs in 1 file
    "au BufNew,BufRead *.yml,*.yaml nmap ;l :w<CR>:!clear; validate_yaml.py "%"<CR>
    "au BufNew,BufRead *.yml,*.yaml nmap ;l :w<CR>:!clear; js-yaml "%" >/dev/null && echo YAML OK<CR>
    au BufNew,BufRead *.yml,*.yaml,autoinstall-user-data nmap ;l :w<CR>:!clear; yamllint "%" && echo YAML OK<CR>
    au BufNew,BufRead *.tf,*.tf.json,*.tfvars,*.tfvars.json nmap ;l :w<CR>:call TerraformValidate()<CR>
    au BufNew,BufRead *.hcl                                 nmap ;l :w<CR>:call TerragruntValidate()<CR>
    au BufNew,BufRead *.pkr.hcl,*.pkr.json nmap ;l :w<CR>:!packer init "%" && packer validate "%" && packer fmt -diff "%" <CR>
    au BufNew,BufRead *.pkr.hcl,*.pkr.json nmap ;f :w<CR>:!packer fmt -diff "%" <CR>

    " more specific matches like pom.xml need to come after less specific matches like *.xml as last statement wins
    au BufNew,BufRead *pom.xml*      nmap ;l :w<CR>:!clear; mvn validate -f "%" \| more -R<CR>
    " check_makefiles.sh is in this repo which should be added to $PATH
    au BufNew,BufRead *Makefile*     nmap ;l :w<CR>:!clear; check_makefiles.sh "%" \| more -R<CR>
    au BufNew,BufRead *build.gradle* nmap ;l :w<CR>:!clear; gradle -b "%" -m clean build \| more -R<CR> | nmap ;r :!gradle -b "%" clean build<CR>
    au BufNew,BufRead *build.sbt*    nmap ;l :w<CR>:!clear; cd "%:p:h" && echo q \| sbt reload "%" \| more -R<CR>
    au BufNew,BufRead *.travis.yml*  nmap ;l :w<CR>:!clear; travis lint "%" \| more -R<CR>
    au BufNew,BufRead serverless.yml nmap ;l :w<CR>:!clear; cd "%:p:h" && serverless print<CR>
    au BufNew,BufRead *Dockerfile*   nmap ;l :w<CR>:!clear; hadolint "%" \| more -R<CR>
    au BufNew,BufRead *docker-compose*.y*ml nmap ;l :w<CR>:!clear; docker-compose -f "%" config \| more -R<CR>
    au BufNew,BufRead *Jenkinsfile*  nmap ;l :w<CR>:!clear; check_jenkinsfiles.sh "%" \| more -R<CR>
    " vagrant validate doesn't take an -f argument so it must be an exact match in order to validate the right thing
    " otherwise you will get an error or false positive
    au BufNew,BufRead Vagrantfile    nmap ;l :w<CR>:!clear; cd "%:p:h" && vagrant validate<CR>
    au BufNew,BufRead *.circleci/config.yml*  nmap ;l :w<CR>:!clear; check_circleci_config.sh \| more -R<CR>
    au BufNew,BufRead *circleci_config.yml*   nmap ;l :w<CR>:!clear; check_circleci_config.sh \| more -R<CR>
    au BufNew,BufRead .pylintrc      nmap ;l :w<CR>:!clear; pylint ./*.py<CR>

    " if a "lint:" header is found then run lint.sh - this allows for more complex file types like Kubernetes yaml
    " which can then be linted for yaml as well as k8s schema
    " XXX: this is overriding all linting regardless of this expansion - instead use a different hotkey L for fast vs full linting
    "if filereadable(expand("%:p")) && match(readfile(expand("%:p")),"lint:")
    "    au BufNew,BufRead *  nmap ;l :w<CR>:!clear; lint.sh "%" \| more -R<CR>
    "endif
endif


" ============================================================================ "
"                           K e y b i n d i n g s
" ============================================================================ "

"nmap <silent> ;c :call Cformat() <CR>
nmap <silent> ;a :,!anonymize.py -a <CR>
nmap          ;A :,!hexanonymize.py --case --hex-only <CR>
nmap <silent> ;b :!git blame "%"<CR>
"nmap <silent> ;c :call ToggleComments()<CR>
nmap <silent> ;c :,!center.py<CR>
nmap <silent> ;e :,!center.py --space<CR>
nmap <silent> ;C :,!center.py --unspace<CR>
" parses current example line and passes as stdin to bash to quickly execute examples from code - see WriteRunLine() further down for example
" messes up interactive vim (disables vim's arrow keys) - calling a terminal reset fixes it
nmap <silent> ;E :call WriteRunLine()<CR> :!reset <CR><CR>
nmap <silent> ;d :r !date '+\%F \%T \%z (\%a, \%d \%b \%Y)'<CR>kJ
"nmap <silent> ;D :Done<CR>
nmap <silent> ;D :%!decomment.sh "%" <CR>
"nmap          ;f :,!fold -s -w 120 \| sed 's/[[:space:]]*$//'<CR>
"nmap <silent> ;h :call Hr()<CR>
nmap <silent> ;h :Hr<CR>
nmap          ;H :call WriteHelp()<CR>
" this inserts Hr literally
"imap <silent> <C-H> :Hr<CR>
nmap <silent> ;I :PluginInstall<CR>
nmap          ;i :'<,'>!readme_generate_index.sh "%" <CR>
nmap <silent> ;j :JHr<CR>
nmap          ;k :w<CR> :! check_kubernetes_yaml.sh "%" <CR>
"nmap <silent> ;' :call Sq()<CR>
" done automatically on write now
"nmap <silent> ;' :call StripTrailingWhiteSpace()<CR>
nmap <silent> ;' :w<CR> :!clear; git diff "%" <CR>
nmap          ;m :w<CR> :call MarkdownIndex() <CR>
nmap          ;n :w<CR> :n<CR>
nmap          ;o :!cd "%:p:h" && git log -p "%:t" <CR>
nmap          ;O :call ToggleGutter()<CR>
nmap          ;p :prev<CR>
"nmap          ;P :call TogglePaste()<CR>
"should be the same thing according to :help pastetoggle but results in vim startup error 'Not an editor command'
"pastetoggle P
nmap          ;P :set paste!<CR>
nmap          ;t :set list!<CR>
nmap          ;q :q<CR>
nmap          ;r :call WriteRun()<CR>
nmap          ;R :call WriteRunDebug()<CR>
"nmap          ;R :!run.sh %:p<CR>
"nmap <silent> ;s :call ToggleSyntax()<CR>
nmap <silent> ;s :,!sqlcase.pl<CR>
"nmap          ;; :call HgGitU()<CR>
" command not found
"nmap          ;; :! . ~/.bashrc; gitu "%" <CR>
nmap          ;; :w<CR> :call GitUpdateCommit() <CR>
nmap          ;/ :w<CR> :call GitAddCommit() <CR>
nmap          ;g :w<CR> :call GitStatus() <CR>
nmap          ;G :w<CR> :call GitLogP() <CR>
nmap          ;L :w<CR> :! lint.sh % <CR>
nmap          ;. :w<CR> :call GitPull() <CR>
nmap          ;[ :w<CR> :call GitPush() <CR>
nmap          ;, :w<CR> :s/^/</ <CR> :s/$/>/ <CR>
" write then grep all URLs that are not mine, followed by all URLs that are mine in reverse order to urlview
" this is so that 3rd party URLs followed by my URLs from within the body of files get higher priority than my header links
nmap <silent> ;u :w<CR> :! bash -c 'grep -vi harisekhon "%" ; grep -i harisekhon "%" \| tail -r' \| urlview <CR> :<CR>
" pass current line as stdin to urlview to quickly go to this url
" messes up interactive vim (disables vim's arrow keys) - calling a terminal reset fixes it
"nmap <silent> ;U :.w !urlview<CR><CR> :!reset<CR><CR>
nmap <silent> ;U :.w !urlopen.sh<CR><CR>
" breaks ;; nmap
"nmap          ;\ :source ~/.vimrc<CR>
"nmap          ;/ :source ~/.vimrc<CR>
"nmap          ;v :source ~/.vimrc<CR>
nmap          ;v :call SourceVimrc()<CR>
nmap          ;V :call WriteRunVerbose()<CR>
nmap          ;w :w<CR>
"nmap          ;x :x<CR>
nmap          ;y :w !pbcopy<CR><CR>
nmap          ;z :call ToggleDebug()<CR>
nmap          ;§ :call ToggleScrollLock()<CR>

"noremap <silent> ,cc :<C-B>silent <C-E>s/^/<C-R>=escape(b:comment_char,'\/')<CR>/<CR>:nohlsearch<CR>
"noremap <silent> ,cu :<C-B>silent <C-E>s/^\V<C-R>=escape(b:comment_char,'\/')<CR>//e<CR>:nohlsearch<CR>

" reloading with these didn't fix above pipe disabling arrow keys but
" adding a terminal reset after the pipe command did fix it
"noremap <Up>    <Up>
"noremap <Down>  <Down>
"noremap <Left>  <Left>
"noremap <Right> <Right>

if has("autocmd")
    au BufNew,BufRead *docker-compose.y*ml   nmap ;r :w<CR>:!clear; docker-compose -f "%" up<CR>
endif

if has("autocmd")
    "au BufNew,BufRead **/haproxy-configs/*.cfg   nmap ;r :w<CR>:!clear; haproxy -f "%:p:h/10-global.cfg" -f "%:p:h/20-stats.cfg" -f "%"<CR>
    au BufNew,BufRead **/haproxy-configs/*.cfg   nmap ;r :w<CR>:!clear; "%:p:h/run.sh" "%"<CR>
    au BufNew,BufRead **/haproxy-configs/*.cfg   nmap ;R :w<CR>:!clear; DEBUG=1 "%:p:h/run.sh" "%"<CR>
endif


" ============================================================================ "
"                               F u n c t i o n s
" ============================================================================ "

" avoids this error when trying to run ;-v nmap to re-source this vimrc:
"
"   E127: Cannot redefine function SourceVimrc: It is in use
"
"function! SourceVimrc()
" This function won't reload as a result, must exit and restart vim
if ! exists("*SourceVimrc")
    function SourceVimrc()
        :source ~/.vimrc
        let vim_tags = system("grep vim: " + expand("%") + " | head -n1 | sed 's/^\"[[:space:]]*vim:/set /; s/:/ /g'")
        " this breaks
        "echo &vim_tags
        "execute "normal!" . &vim_tags
        ":! grep vim: expand("%") | sed 's/\#//'
        :echo "\n"
        :echo "Currently set options:"
        :echo "\n"
        :set ts sts sw et filetype
    endfunction
endif

":! bash -c 'vim -c "source %" -c "q" && echo "ViM basic lint validation passed" || "ViM basic lint validation failed"'
"":! if type -P vint &>/dev/null; then vint "%"; fi
function! LintVimrc()
  let l:vimrc_path = expand('~/.vimrc')

  echo "Sourcing ~/.vimrc file..."
  try
    execute 'source' l:vimrc_path
    echohl InfoMsg | echo "No syntax errors found in .vimrc." | echohl None
  catch
    echohl ErrorMsg | echo "Error found in .vimrc while sourcing." | echohl None
    return
  endtry

  if executable('vint')
    echo "Running vint..."
    let l:vint_output = system('vint ' . l:vimrc_path)
    if v:shell_error
      echohl ErrorMsg | echo l:vint_output | echohl None
    else
      echohl InfoMsg | echo "No linting issues found by vint." | echohl None
    endif
  else
    echohl WarningMsg | echo "vint is not installed or not found in PATH." | echohl None
  endif
endfunction

function! ToggleSyntax()
    if exists("g:syntax_on")
        syntax off
    else
        syntax enable
    endif
endfunction

function! ToggleComments()
    :let comment_char = '#'
    :let comment_prefix = '^' . comment_char
    echo comment_prefix
    if getline('.') =~ comment_prefix
        :s/^\=:comment_char//
    else
        :s/^/\=:comment_char/
    endif
endfunction

" setting this high keeps cursor in middle of screen
":set so=999
function! ToggleScrollLock()
    if &scrolloff > 0
        :set scrolloff=0
    else
        :set scrolloff=999
    endif
endfunction

" simpler to call: set paste!
"function! TogglePaste()
"    if &paste > 0
"        :set nopaste
"    else
"        :set paste
"    endif
"endfunction

" changing this setting has no effect on vim gutter in real time
function! ToggleGutter()
    :let g:gitgutter_enabled = 0
    "if g:gitgutter_enabled > 0
    "if get(g:, 'gitgutter_enabled', 0) > 0
    "    :let g:gitgutter_enabled = 0
    "else
    "    :let g:gitgutter_enabled = 1
    "endif
endfunction

function! ToggleDebug()
    if $DEBUG
        echo "DEBUG disabled"
        let $DEBUG=""
    else
        echo "DEBUG enabled"
        let $DEBUG=1
    endif
endfunction

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

" ============================================================================ "
"                            G i t   F u n c t i o n s
" ============================================================================ "

" works better than a straight nmap which sometimes fails to execute and re-sourcing .vimrc doesn't solve it
" without exiting vim - this is buggy behaviour that doesn't seem to happen when using functions instead

function! GitUpdateCommit()
    :! bash -ic 'cd "%:p:h" && gitu "%:t" '
endfunction

function! GitAddCommit()
     ! bash -ic 'add "%"'
endfunction

function! GitStatus()
    :! bash -ic 'cd "%:p:h" && st'
endfunction

function! GitLogP()
    :! bash -ic 'cd "%:p:h" && git log -p "%:t"'
endfunction

function! GitPull()
    :! bash -ic 'cd "%:p:h" && pull'
endfunction

function! GitPush()
    :! bash -ic 'cd "%:p:h" && push'
endfunction

" ============================================================================ "

function! MarkdownIndex()
    :! markdown_replace_index.sh "%"
endfunction

" superceded by anonymize.py from DevOps Python tools repo, called via hotkey ;a declared above
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

function! Anonymize()
    ": call RemoveIPs()
    ": call RemoveMacs()
    ": call RemoveDomains()
    " Anonymizer is found in adjacent DevOps Python Tools repo which should be added to $PATH
    " there is also a faster version in DevOps Perl Tools repo
    :%!anonymize.py --all
endfunction

" StripQuotes()
function! Sq()
    :s/["']//g
endfunction

function! StripTrailingWhiteSpace()
    :%s/[[:space:]]*$//
endfunction

function! WriteHelp()
    :w
    if &filetype == 'go'
        :! go run "%:p" --help 2>&1 | less
    elseif expand('%:t') == 'Makefile'
        :call Make('help')
    else
        :! "%:p" --help 2>&1 | less
    endif
endfunction

function! WriteRun()
    :w
    if &filetype == 'go'
        " TODO: consider switching this to go build and then run the binary as
        " this gets stdout only at the end so things like welcome.go don't get
        " the transition effects when run like this
        :! eval go run "%:p" `$bash_tools/lib/args_extract.sh "%:p"` 2>&1 | less
    " doesn't work, probably due to no first class support so just get file extension
    "elseif &filetype == 'tf'
    elseif expand('%:e') == 'tf'
        ":call TerraformPlan()
        :call TerraformApply()
    elseif expand('%:t') =~ '\.pkr\.\(hcl\|json\)'
        :! packer init "%:p" && packer build "%:p"
    elseif expand('%:t') == 'Makefile'
        :call Make()
    elseif expand('%:t') == 'Dockerfile'
        " "%:p:h" is dirname
        if filereadable(join([expand("%:p:h"), "Makefile"], "/"))
            :call Make()
        else
            :! docker build "%:p:h"
        endif
    elseif expand('%:t') == 'Gemfile'
        " "%:p:h" is dirname
        :! cd "%:p:h" && bundle install
    "elseif ! empty(matchstr(expand('%:t'), 'cloudbuild.*.yaml'))
    elseif expand('%:t') =~ 'cloudbuild.*\.ya\?ml'
        :call CloudBuild()
    elseif expand('%:t') == 'kustomization.yaml'
        :! bash -c 'cd "%:p:h" && kustomize build --enable-helm' 2>&1 | less
    elseif expand('%:t') == '.envrc'
        :! bash -c 'cd "%:p:h" && direnv allow .' 2>&1 | less
    elseif executable('run.sh')
        " this only works for scripts
        ":! eval "%:p" `$bash_tools/lib/args_extract.sh "%:p"`  2>&1 | less
        " but this now works for config files too which can have run headers
        " instead of args headers
        :! "run.sh" "%:p" 2>&1 | less
    else
        echo "unsupported file type and run.sh not found in PATH"
    endif
endfunction

function! WriteRunVerbose()
    :let $VERBOSE=1
    :call WriteRun()
    :let $VERBOSE=""
endfunction

function! WriteRunDebug()
    :let $DEBUG=1
    :call WriteRun()
    :let $DEBUG=""
endfunction

function! WriteRunLine()
    :w
    if &filetype == 'go'
        " TODO: consider switching this to go build and then run the binary as
        " this gets stdout only at the end so things like welcome.go don't get
        " the transition effects when run like this
        :.w ! sed 's/^[[:space:]]*\#// ; s|\$0|%:p| ; s|\${0\#\#\*\/}|%:p|' | xargs go run 2>&1 | less
    elseif expand('%:t') == 'Makefile' " || expand('%:t') == 'Makefile.in'
        let target = split(getline('.'), ':')[0]
        call Make(target)
    else
        " $0 => ./script.sh  ${0##*/} => ./script.sh
        " super crafy hack to get jq options injected via jq() function from interactive profile without doing
        " bash -i which causes prompt issues and 'no job control' message, and tee'ing to /dev/stderr instead of
        " using set -x which would exposing the inner workings and obscure the executed command
        .w ! sed 's/^[[:space:]]*\#// ; s|\$0|%:p| ; s|\${0\#\#\*\/}|%:p|' | bash -c '. $bash_tools/.bash.d/aliases.sh; . $bash_tools/.bash.d/functions.sh; eval "$(cat | tee /dev/stderr)"' 2>&1 | less
    endif
    :silent exec "!echo; read -p 'Press enter to return to vim'"
endfunction

" variable number of args like *args in python
function! Make(...)
    " '%:p:h' is dirname
    ":! cd "%:p:h" && make join(map(a:000, 'shellescape(v:val)'), ' ')
    " this works and nicely pages but only outputs at the end, which is ok for help
    " but bad for actual make builds which are long and look like they hang
    ":echo system('cd ' . expand('%:p:h') . ' && make ' . join(a:000, ''))
    :exe '! cd "%:p:h" && make ' . join(a:000, '') . ' | more'
endfunction

" Hashicorp Terraform
function! TerraformValidate()
    " remove terraform plan copy-pasted removals for fast backporting
    :%s/^[[:space:]]*[-~][[:space:]]//e
    :%s/[[:space:]]->[[:space:]].*$//e
    :!clear; bash -c 'if [ -d "%:p:h"/.terraform ]; then cd "%:p:h"; fi; { terraform fmt -diff; terraform validate; } | more -R'
endfunction

function! TerragruntValidate()
    :%s/[[:space:]]->[[:space:]].*$//e
    :!clear; bash -c 'if [ -d "%:p:h"/.terraform ]; then cd "%:p:h"; fi; { terragrunt hclfmt --terragrunt-diff; terragrunt validate; } | more -R'
endfunction

function! TerraformPlan()
    " '%:p:h' is dirname
    :! bash -c 'if [ -d "%:p:h"/.terraform ]; then cd "%:p:h"; fi; terraform plan'
endfunction

function! TerraformApply()
    :! bash -c 'if [ -d "%:p:h"/.terraform ]; then cd "%:p:h"; fi; terraform apply'
endfunction

" GCP Google Cloud Build
function! CloudBuild()
    " '%:p:h' is dirname
    let cloudbuild_yaml = expand('%:t')
    :exe '! cd "%:p:h" && gcloud builds submit --config ' . cloudbuild_yaml . ' .'
endfunction


" ============================================================================ "
"                   L o c a l   C o n f i g   S o u r c i n g
" ============================================================================ "

" either works, requires expand()
"let MYLOCALVIMRC = "~/.vimrc.local"
"let MYLOCALVIMRC = "$HOME/.vimrc.local"

" source a config file only if it exists
function! SourceIfExists(file)
  if filereadable(expand(a:file))
    exe 'source' a:file
  endif
endfunction

call SourceIfExists("~/.vimrc.local")
call SourceIfExists("~/.vim/colors.vim")

if has('gui_running')
  call SourceIfExists("~/.gvimrc.local")
endif
