#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2012 (forked from .bashrc)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#             R e v i s i o n   C o n t r o l  -  M e r c u r i a l
# ============================================================================ #

type -P hg &>/dev/null || return 0

alias hgi=hgignore
alias hgrc='$EDITOR ~/.hgrc'

# HG doesn't record dirs and there is no .hg per subdir, rather than traverse upwards checking filesystem boundaries use hg tools themselves
isHg(){
    local target="${1:-.}"
    # There aren't local .hg dirs everywhere only at top level so this is difficult in bash
    #if [ -d "$target/.hg" -o -d "$(dirname "$target")/.hg" ]; then
    # shortcut for efficiency
    if [ -d "$target/.hg" ] ||
       [ -d "${target%/*}/.hg" ]; then # || hg parents "$target" &>/dev/null; then # can only call this on files not dirs anyway since Hg doesn't track dirs
        return 0
    #elif [ -f "$target" ] && hg parents "$target"; then
    #    return 0
    #elif hg status "$target" &>/dev/null; then # Doesn't work at all always returns 0 if a subdir of a repo and just blank even if in ignores
        # Unfortunately the -P switch only supports a single pattern so we can't use --file
        #grep -qP -f "$(hg root)/.hgignore"
        # algorithm horribly inefficient, was going to rewrite in perl isHg.pl but see futher down
        #while read regex; do
        #    grep "^[[:space:]]*$" <<< "$regex" && continue
        #    abs_path="$(abs_path "$target")"
        #    abs_path="${abs_path/$(hg root)\/}"
        #    grep -qP "$regex" <<< "$abs_path" && return 1
        #done < "$(hg root)/.hgignore"
    #    return 0
    #elif [ -d "$target" ]; then
    #    echo "WARNING: cannot call hg on a dir, $target is a dir so this returns false and will fall through"
    #    return 1
    # finally found a reasonably efficient way to handle all cases
    # trick to return False on subdirs which are not handled by Mercurial
elif [ -n "$(hg log --limit 1 "$target" 2>/dev/null)" ]; then
        return 0
    else
        return 1
    fi
}

hgignore(){
    #pushd "$srcdir" &>/dev/null
    local hgroot
    hgroot="$(hg root)"
    [ -n "$hgroot" ] || return 1
    "$EDITOR" "$hgroot/.hgignore"
    #popd &>/dev/null
}

hgci(){
    local hgcimsg=""
    for x in "$@"; do
        if hg st "$x" | grep -q "^[?A]"; then
            hgcimsg+="$x, "
        fi
    done
    [ -z "$hgcimsg" ] && return 1
    hgcimsg="${hgcimsg%, }"
    hgcimsg="added $hgcimsg"
    hg add -- "$@" &&
    echo "committing $*"
    hg ci -m "$hgcimsg" -- "$@"
}

hgrm(){
    hg rm -- "$@" &&
    hg ci -m "removed $*" -- "$@"
}

hgrevertrm(){
    hg revert "$@"
    rm -v -- "$@"
}

hgrename(){
    hg mv -- "$1" "$2" &&
    hg ci -m "renamed $1 to $2" -- "$1" "$2"
}

hgmv(){
    hg mv -- "$1" "$2" &&
    hg ci -m "moved $1 to $2" -- "$1" "$2"
}

hgl(){
    hg log "$@" | less
}

hgu(){
    [ -n "$1" ] || { echo "ERROR: must supply arg"; return 1; }
    [ "$(hg diff "$@" | wc -l)" -gt 0 ] || return
    hg diff -- "$@" | more &&
    read -r &&
    echo "committing $*" &&
    hg ci -m "updated $*" -- "$@"
}

#hhgu(){
#    # all playlists end in \n from now on via paste_playlists.sh fix
#    [ -n "$1" ] || { echo "ERROR: must supply arg"; return 1; }
#    pushd "$music" >/dev/null
#    spotify/validate_playlists.sh "$1" || { echo "Playlist validation failed"; return 1; }
#    spotify/validate_playlist_lengths.sh "$1" || { echo "Playlist dump length validation failed"; return 1; }
#    [ `hg st "$1" "spotify/$1" | wc -l` -gt 0 ] || { echo "No changes in either uri or track lists"; return 0; }
#    local target="${1##*/}"
#    local target_tip="$(dirname "$target")/.$(basename "$target").tip"
#    hg cat "$target" | spotify/normalize_tracknames.pl > "$target_tip"
#    cat "$target" | spotify/normalize_tracknames.pl > ".$target"
#    if [ -z "$(diff -iwu "$target_tip" ".$target")" ]; then
#        echo "Noop changes only, committing..."
#        hg mydiff "$target" |
#        #egrep '^\+' | tee /dev/stderr |
#        grep -v '^[+-][+-][+-]' # | sl --no-locking
#        hg ci -m "updated $target" "$target" "spotify/$target"
#        return $?
#    elif diff -iwu "$target_tip" ".$target" | grep -q '^-[^-]'; then
#        local diffs="$(
#        { hg mydiff "$target"
#          hg mydiff "spotify/$target"
#        })"
#        local removals="$(grep -c "^-[^-]" <<< "$diffs")"
#        local additions="$(grep -c "^+[^+]" <<< "$diffs")"
#        diffs="$(echo "$diffs" |
#        egrep "^[+-]" |
#        spotify/normalize_tracknames.pl |
#        diffnet.pl -iw
#        )"
#        if [ -z "$diffs" ]; then
#            echo "Noop changes to tracks, committing..."
#        elif ! echo "$diffs" | grep -q '^-[^-]'; then
#            echo "Net diff shows only playlist additions, committing..."
#            echo "$diffs" |
#            more
#        else
#            {
#            echo "$additions additions $removals removals"
#            echo "$diffs"
#            } |
#            more &&
#            read || return
#        fi
#        hg ci -m "updated $target" "$target" "spotify/$target"
#    else
#        echo "Only playlist additions detected, committing..."
#        hg mydiff "$target" |
#        #grep -v '^[+-][+-][+-]'
#        egrep "^[+-]"
#        hg ci -m "updated $target" "$target" "spotify/$target"
#        return $?
#    #    echo "No additions or removals detected, playlist dump must currently be in progress"
#    #    return 1
#    fi
#    popd &>/dev/null
#}

# equiv to using the 3rd party shelve extension since HG doesn't have this Git Stash functionality
hgshelve(){
    local hgroot
    hgroot="$(hg root)"
    [ -f "$hgroot/shelve.diff" ] &&
        { echo "$hgroot/shelve.diff already exists, aborting for safety to not lose changes"; return 1; }
    hg diff > "$hgroot/shelve.diff"
    hg revert -a
}

# Then merge, hg up etc, then unshelve

hgunshelve(){
    hg import --no-commit "$hgroot/shelve.diff" # && rm -v "$srcdir/shelve.diff"
}

hgdiff(){
    local filename="${1:-}"
    [ -n "$filename" ] || { echo "usage: hgdiff filename"; return 1; }
    hg diff -- "$filename" > "/tmp/hgdiff.tmp"
    diffnet.pl "/tmp/hgdiff.tmp"
}
