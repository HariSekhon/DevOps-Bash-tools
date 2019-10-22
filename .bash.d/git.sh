#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ============================================================================ #
#                   R e v i s i o n   C o n t r o l  -  G i t
# ============================================================================ #

# Primary revision control system
#
# if svn.sh and hg.sh functions are enabled, detects and calls svn and mercurial commands if inside those repos so some of the same commands work dynamically

# set location where you check out all the github repos
export github=~/github

export GIT_PAGER="less -RFX --tabs=4"
# shellcheck disable=SC2230
#if [ -z "${GIT_PAGER:-}" ] && \
if type -P diff-so-fancy &>/dev/null; then
    # pre-loading a pattern to 'n' / 'N' / '?' / '/' search through will force you in to pager and disregard -F / --quit-if-one-screen
    #export GIT_PAGER="diff-so-fancy --color=yes | less -RFX --tabs=4 --pattern '^(Date|added|deleted|modified): '"
    export GIT_PAGER="diff-so-fancy --color=yes | $GIT_PAGER"
fi

alias gitconfig="\$EDITOR ~/.gitconfig"
alias gitignore="\$EDITOR ~/.gitignore_global"
alias gitrc=gitconfig

alias add=gitadd
alias co=checkout
alias commit="git commit"
alias clone="git clone"
alias gitci=commit
alias ci=commit
alias gitco=checkout
alias up=pull
alias u=up
alias gitp="git push"
alias gdiff="git diff"
# bypasses diff-so-fancy, could also just pipe through | cat to disable pager and color effects
alias gdiff2="git --no-pager diff"
alias gdiffm="gdiff origin/master.."
alias branch="githg branch"
alias br=branch
alias tag="githg tag"
alias um=updatemodules
alias gbrowse=gitbrowse
#type browse &>/dev/null || alias browse=gbrowse

# git fetch -p or git remote prune origin
alias prune="co master; git pull; git remote prune origin; git branch --merged | grep -v -e '^\*' -e 'master' | xargs git branch -d"

# don't use this unless you are a git pro and understand unwinding history and merge conflicts
alias GRH="git reset HEAD^"

alias master="switchbranch master"
alias prod="switchbranch prod"
alias staging="switchbranch staging"
alias stage=staging
alias dev="switchbranch dev"

gitgc(){
    if ! [ -d .git ]; then
        echo "not at top of a git repo, not .git/ directory found"
        return 1
    fi
    du -sh .git
    git gc --aggressive
    du -sh .git
}

gitbrowse(){
    browser "$(git remote -v | awk '/https:/{print $2}' | sed 's,://.*@,://,' | head -n1)"
}

install_git_completion(){
    if ! [ -f ~/.git-completion.bash ]; then
        wget -O ~/.git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
    fi
}

# shellcheck disable=SC1090
[ -f ~/.git-completion.bash ] && . ~/.git-completion.bash

# usage: gi python,perl,go
#        gi list
gitignore_api(){
    local url
	local langs
	local options=()
    local args=()
    # noop - set to use 'tr' to separate items to newlines when given the 'list' arg
    local commas_to_newlines="cat"
	for arg; do
        if [ "$arg" = -- ]; then
            options+=("$arg")
        else
            args+=("$arg")
        fi
    done
	# take args 'python perl', store as 'python,perl' for the API call
	langs="$(IFS=, ; echo "${args[*]}")"
    url="https://www.gitignore.io/api/$langs"
    if [ "$langs" = "list" ]; then
        commas_to_newlines="tr ',' '\n'"
    fi
    {
    if hash curl 2>/dev/null; then
        curl -sL "${options[*]}" "$url"
    elif hash wget 2>/dev/null; then
        wget -O - "${options[*]}" "$url"
    fi
    } | eval "$commas_to_newlines"
    echo
}
alias gi=gitignore_api


isGit(){
    local target=${1:-.}
    # There aren't local .hg dirs everywhere only at top level so this is difficult in bash
    if [ -d "$target/.git" ]; then
        return 0
    elif [ -f "$target" ] &&
         [ -d "${target%/*}/.git" ]; then
        #-o "$target/../.git" -o "${target%/*}/../.git" ]; then
        return 0
    else
        # This is because git command doesn't return correctly when running from outside git root, complains there is not .git
        pushd "$(dirname "$target")" >/dev/null || return 1
        # subdirs which are not handled by Git fail isGit
        # returns false for a newly added not committed dir
        #if git log -1 "$target" 2>/dev/null | grep -q '.*'; then
        if [ -n "$(git log -1 "$(basename "$target")" 2>/dev/null)" ]; then
            # shellcheck disable=SC2164
            popd &>/dev/null
            return 0
        fi
        # shellcheck disable=SC2164
        popd &>/dev/null
        return 2
    fi
}


st(){
  # shellcheck disable=SC2086
  {
    local target="${1:-.}"
    shift
    if ! [ -e "$target" ]; then
        echo "$target does not exist"
        return 1
    fi
    local target_basename
    local target_dirname
    target_basename="$(basename "$target")"
    target_dirname="$(dirname "$target")"
    #if [ -f "Vagrantfile" ]; then
    #    echo "> vagrant status"
    #    vagrant status
    # shellcheck disable=SC2166
    if [ "$target_basename" = "github" ] ||
       [ "$target" = "." -a "$(pwd)" = ~/github ]; then
        hr
        for x in "$target"/*; do
            [ -d "$x" ] || continue
            pushd "$x" >/dev/null || { echo "failed to pushd to '$x'"; return 1; }
            if git remote -v | grep -qi harisekhon; then
                echo "> GitHub: git status $x $*"
                git status . "$@"
                echo
                hr
                echo
            fi
            # shellcheck disable=SC2164
            popd >/dev/null
        done
    elif isGit "$target"; then
        if [ -d "$target" ]; then
            pushd "$target" >/dev/null || { echo "Error: failed to pushd to $target"; return 1; }
            echo "> git stash list" >&2
            git stash list && echo
            echo "> git status $target $*" >&2
            #git -c color.status=always status -sb . "$@"
            git -c color.status=always status . "$@"
        else
            pushd "$target_dirname" >/dev/null || { echo "Error: failed to pushed to '$target_dirname'"; return 1; }
            echo "> git status $target $*" >&2
            git -c color.status=always status "$target_basename" "$@"
        fi
        #git status "$target" "${*:2}"
        # shellcheck disable=SC2164
        popd &>/dev/null
    elif type isHg &>/dev/null && isHg "$target"; then
        echo "> hg status $target $*" >&2
        hg status "$target" "$@" | grep -v "^?"
        # to see relative paths instead of the default absolute paths
        #hg status "$(hg root)"
    elif type isSvn &>/dev/null && isSvn "$target"; then
        echo "> svn st $*" >&2
        svn st --ignore-externals "$target" "$@" | grep -v -e "^?" -e "^x";
    else
        echo "not a revision controlled resource as far as bashrc can tell"
    fi
  } |
  # more calls less on Mac, and gets stuck in interactive mode ignoring the less alias switches
  #more -R -n "$((LINES - 3))"
  #less -RFX
  eval ${GIT_PAGER:-cat}
}

pull(){
    local target="${1:-.}"
    if ! [ -e "$target" ]; then
        echo "$target does not exist"
        return 1
    fi
    local target_basename
    target_basename="$(basename "$target")"
    # shellcheck disable=SC2166
    if [ "$target_basename" = "github" ] || [ "$target" = "." -a "$(pwd)" = "$github" ]; then
        for x in "$target"/*; do
            [ -d "$x" ] || continue
            # get last character of string
            [ "${x: -1}" = 2 ] && continue
            pushd "$x" >/dev/null || { echo "failed to pushd to '$x'"; return 1; }
            if git remote -v | grep -qi harisekhon; then
                echo "> GitHub: git pull $x ${*:2}"
                git pull "${@:2}"
                echo
            fi
            # shellcheck disable=SC2164
            popd >/dev/null
        done
        return
    elif isGit "$target"; then
        pushd "$target" >/dev/null &&
        echo "> git pull -v ${*:2}" >&2
        git pull -v "${@:2}"
        git submodule update
        #local orig_branch=$(git branch | awk '/^\*/ {print $2}')
        #for branch in $(git branch | cut -c 3- ); do
        #    git checkout -q "$branch" &&
        #    echo -n "$branch => " &&
        #    git pull -v
        #    echo
        #    echo
        #done
        #git checkout -q "$orig_branch"
        # shellcheck disable=SC2164
        popd >/dev/null
    elif type isHg &>/dev/null && isHg "$target"; then
        pushd "$target" >/dev/null &&
        echo "> hg pull && hg up" >&2  &&
        hg pull && hg up
        # shellcheck disable=SC2164
        popd >/dev/null
    elif type isSvn &>/dev/null && isSvn "$target"; then
        echo "> svn up $target" >&2
        svn up "$target"
    else
        echo "not a revision controlled resource as far as bashrc can tell"
        return 1
    fi
}

checkout(){
    if isGit "."; then
        git checkout "$@";
    else
        echo "not a Git checkout, cannot switch to branch $*"
        return 1
    fi
}

gitadd() {
    local gitcimsg=""
    for x in "$@"; do
        if git status -s "$x" | grep "^[?A]"; then
            gitcimsg+="$x, "
        fi
    done
    [ -z "$gitcimsg" ] && return 1
    gitcimsg="${gitcimsg%, }"
    gitcimsg="added $gitcimsg"
    git add "$@" &&
    git commit -m "$gitcimsg" "$@"
}

# shellcheck disable=SC2086
gitu(){
    if [ -z "$1" ]; then
        echo "usage: gitu <file>"
        return 3
    fi
    local targets
    if [ -n "$(git diff "$@")" ]; then
        targets="$*"
    else
        # follow symlinks to the actual files because diffing symlinks returns no changes
        targets="$(resolve_symlinks "$@")"
    fi
    local basedir
    # go to the highest directory level to git diff inside the git repo boundary, otherwise git diff will return nothing
    basedir="$(basedir $targets)" &&
    pushd "$basedir" >/dev/null &&
    targets="$(strip_basedirs $basedir $targets)" || return 1
    # shellcheck disable=SC2086
    if [ -z "$(git diff $targets)" ]; then
        popd >/dev/null || :
        return
    fi
    # shellcheck disable=SC2086
    git diff $targets &&
    read -r &&
    git add $targets &&
    echo "committing $targets" &&
    git commit -m "updated $targets" $targets
    popd >/dev/null || :
}

#githgu(){
#    target="${1:-.}"
#    #count=0
#    while [ -L "$target" ]; do
#        #target="$(readlink "$target")"
#        #let count+=1
#        #if [ $count -gt 10 ]; then
#        #    echo "looping over links more than 10 times in hggitu! "
#        #    exit 2
#        #fi
#        echo "$target is a symlink! "
#        return 1
#    done
#    if ! [ -e "$target" ]; then
#        echo "$target does not exist"
#        return 1
#    fi
#    if isGit "$target"; then
#        echo "> git" >&2
#        #if [ -d "$target" ]; then
#        #    pushd "$target" >/dev/null
#        #else
#        #    pushd "$(dirname "$target")" >/dev/null
#        #fi
#        #"$srcdir2/gitu" "${target##*/}" &&
#        gitu "$target"
#        #popd >/dev/null
#    elif type isHg &>/dev/null && isHg "$target"; then
#        echo "> hg" >&2
#        #if [ -d "$target" ]; then
#        #    pushd "$target" >/dev/null
#        #else
#        #    pushd "$(dirname "$target")" >/dev/null
#        #fi
#        #"$srcdir2/hgu" "${target##*/}" &&
#        hgu "$target"
#        #popd >/dev/null
#    # Not supporting SVN any more
#    #elif type isSvn &>/dev/null && isSvn "$target"; then
#    #    echo "> svn" >&2
#    #    svnu "$target"
#    else
#        echo "not a revision controlled resource as far as bashrc can tell"
#        return 1
#    fi
#}

push(){
    pull . "$@" || return 1
    if isGit .; then
        echo "> git push -v $*"
        #for remote in $(git remote); do
        #    git push -v $remote $@
        #done
        git push -v "$@"
    elif type isHg &>/dev/null && isHg .; then
        echo "> hg push $*"
        hg push "$@"
    else
        echo "not in a Git or Mercurial controlled directory"
        return 1
    fi
}

switchbranch(){
    if isGit "."; then
        git checkout "$1";
    elif type isHg &>/dev/null && isHg "."; then
        hg update "$1"
    else
        echo "not a Git / Mercurial checkout, cannot switch to branch $1"
        return 1
    fi
}

gitrm(){
    git rm "$@" &&
    git commit -m "removed $*" "$@"
}

gitrename(){
    git mv "$1" "$2" &&
    git commit -m "renamed $1 to $2" "$1" "$2"
}

gitmv(){
    git mv "$1" "$2" &&
    git commit -m "moved $1 to $2" "$1" "$2"
}

gitd(){
    git diff "${@:-.}"
}

# doesn't need pipe | less, git drops you in to less anyway
gitl(){
    git log --all --name-status --graph --decorate "$@"
}

gitlp(){
    git log -p "$@"
}

gitl2(){
    git log --pretty=format:"%n%an => %ar%n%s" --name-status "$@"
}

githg(){
    if isGit .; then
        git "$@"
    elif type isHg &>/dev/null && isHg .; then
        hg "$@"
    else
        echo "not a Git/Mercurial checkout"
        return 1
    fi
}

retag(){
    local tag1="$1"
    local checksum="$2"
    local additional_tags="${*:2}"
    for tag in $tag1 $additional_tags; do
        git tag -d "$tag" || :
        echo "Creating git tag '$tag'"
        # quoting checksum causes failure with unrecognized checksum ''
        git tag "$tag" "$checksum"
        git tag |
        grep -qF "$tag" ||
            echo "FAILED"
    done
}

gitfind(){
    local refids
    refids="$(git log --all --oneline | grep "$@" | awk '{print $1}')"
    printf "Branches:\n\n"
    for refid in $refids; do
        git branch --contains "$refid"
    done | sort -u
    printf "\nTags:\n\n"
    for refid in $refids; do
        git tag --contains "$refid"
    done | sort -u
}

updatemodules(){
    if isGit .; then
        git pull
        #git submodule update --init --remote
        for submodule in $(git submodule | awk '{print $2}'); do
            if [ -d "$submodule" ] && ! [ -L "$submodule" ]; then
                pushd "$submodule" || continue
                git stash
                git checkout master
                git pull
                # shellcheck disable=SC2164
                popd
            fi
        done
        echo
        for submodule in $(git submodule | awk '{print $2}'); do
            if [ -d "$submodule" ] && ! [ -L "$submodule" ] && ! git status "$submodule" | grep -q nothing; then
                git commit -m "updated $submodule" "$submodule" || break
            fi
        done &&
        make updatem ||
        echo FAILED
        echo
        for submodule in $(git submodule | awk '{print $2}'); do
            if [ -d "$submodule" ] && ! [ -L "$submodule" ]; then
                pushd "$submodule" || continue
                git stash pop
                # shellcheck disable=SC2164
                popd
            fi
        done
    else
        echo "Not a Git repository! "
        return 1
    fi
}

upl(){
    local repos="pylib pytools lib tools bash-tools nagios-plugins npk"
    # pull all repos first so can handle merge requests if needed
    for repo in $repos; do
        echo
        echo "* Pulling latest repo changes:  $repo"
        echo
        pushd "$github/$repo" &&
        git pull &&
        popd &&
        hr || return 1
    done
    echo
    echo "UNATTEND FROM HERE"
    echo
    for repo in $repos; do
        echo
        echo "* Performing latest submodule updates:  $repo"
        echo
        pushd "$github/$repo" &&
        ! updatemodules 2>&1 | tee /dev/stderr | grep -e ERROR -e FAIL &&
        git push &&
        popd &&
        hr || return 1
    done
}

stagemerge(){
    if isGit "."; then
        git checkout prod    && git pull &&
        git checkout staging && git pull &&
        git merge prod
        git checkout prod
    else
        echo "Not a Git working copy";
    fi
}

gitdiff(){
    local filename="${1:-}"
    [ -n "$filename" ] || { echo "usage: gitdiff filename"; return 1; }
    git diff "$filename" > "/tmp/gitdiff.tmp"
    diffnet.pl "/tmp/hgdiff.tmp"
}

revert_typechange(){
    # want splitting to separate filenames
    # shellcheck disable=SC2046
    co $(git status --porcelain -s "${1:-.}" | awk '/^.T/{print $2}')
}

rm_untracked(){
    # iterate on explicit targets only
    # intentionally not including current directory to avoid accidentally wiping out untracked files - you must specify "rm_untracked ." if you really intend this
    for x in "${@:-}"; do
        # want splitting to separate filenames
        # shellcheck disable=SC2046
        rm -v $(git status --porcelain -s "$x" | awk '/^??/{print $2}')
    done
}
