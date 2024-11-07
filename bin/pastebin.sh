#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2010-05-18 10:40:36 +0100 (Tue, 18 May 2010)
#  (just discovered in private repo and ported here)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Uploads a file to https://pastebin.com and copies the resulting URL to your clipboard

Prompts to confirm the content before uploading for your safe review as this defaults to PUBLIC but not listed

Expiry defaults to 1 day

Required: an API key in environment variable PASTEBIN_API_KEY

Recommended: use anonymize.py or anonymize.pl from the adjacent DevOps-Python-tools or DevOps-Perl-tools repos

Optional: decomment.sh

Syntax Highlighting: the API doesn't infer syntax highlighting based on the filename extension,
                     so tries to auto-infer it in this script for some common formats based on the file extension.
                     You can override this as an argument

See values for parameters here:

    https://pastebin.com/doc_api#4

Knowledge Base page: https://github.com/HariSekhon/Knowledge-Base/blob/main/upload-sites.md

If you use this a lot you will hit this error from the API:

    Bad API request, Post limit, maximum pastes per 24h reached
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename> [<expiry> <private> <format>]"

help_usage "$@"

min_args 1 "$@"

check_env_defined PASTEBIN_API_KEY

file="$1"
expiry="${2:-${PASTEBIN_EXPIRY:-1D}}"
private="${3:-1}"  # 1=unlisted (default), 0=public, 2=private
format="${4:-text}"  # syntax highlighting

if ! [[ "$private" =~ ^(0|1|2)$ ]]; then
    usage "Invalid value for private arg, must be one of: 0, 1 or 2 for public, unlisted or private respectively"
fi

if ! [[ "$expiry" =~ ^[[:digit:]][[:alpha:]]$ ]]; then
    usage "Invalid value for expiry arg, must be in format: <integer><uppercase_unit_of_time_character>"
fi
expiry="$(tr '[:lower:]' '[:upper:]' <<< "$expiry")"

# Do not allow reading from stdin because it does not allow the prompt safety
#if [ "$file" = '-' ]; then
#    timestamp "reading from stdin"
    #file="/dev/stdin"
#else
    timestamp "reading from file: $file"
#fi

content="$(cat "$file")"
echo

cat <<EOF
Here is what will be pastebin-ed:

$content

EOF

read -r -p "Continue? [y/N] " answer
echo

check_yes "$answer"
echo

if [ "$format" = text ]; then
    ext="${file##*.}"

    shopt -s nocasematch

    # adapted from:
    #
    #   https://pastebin.com/doc_api#5

    case "$ext" in
        apache | log) format=apache ;;
        apt) format=apt_sources ;;
        as | actionscript) format=actionscript ;;
        asm | s) format=asm ;;
        bat | cmd) format=dos ;;
        bib) format=bibtext ;;
        clj | cljs | cljr | cljc | cljd | edn) format=clojure ;;
        cpp | h | hpp) format=cpp ;;
        cs) format=csharp ;;
        el) format=emacs-lisp ;;
        eml | email) format=email ;;
        erl | hrl) format=erlang ;;
        fs) format=fsharp ;;
        groovy | gvy | gy | gsh) format=groovy ;;
        hs | lhs) format=haskell ;;
        java | jsh ) format=java ;;
        js) format=javascript ;;
        kt | kts | kexe | klib) format=kotlin ;;
        lsp) format=lisp ;;
        m) format=matlab ;;
        md) format=markdown ;;
        ml) format=ocaml ;;
        pas) format=pascal ;;
        php | php3 | php4) format=php ;;
        pl | pm | t) format=perl ;;
        plt | gnu | gpi | gih) format=gnuplot ;;
        pp) format=puppet ;;
        psql | postgres | postgresql) format=postgresql ;;
        r) format=rsplus ;;
        rb) format=ruby ;;
        rs) format=rust ;;
        sc | scala) format=scala ;;
        scpti | scptd) format=applescript ;;
        sh | bash) format='bash' ;;
        spec) format=rpmspec ;;
        ssh/config) format=sshconfig ;;
        tex) format=latex ;;
        ts) format=typescript ;;
        v) format=verilog ;;
        vb) format=vbnet ;;
        vbs | vbscript) format=vbscript ;;
        vim | vimscript) format=vim ;;
        yml | yaml) format=yaml ;;
        # the rest try for straight matches - some of these should probably be moved above with more file extension variations
        abap|actionscript3|ada|aimms|algol68|applescript|arduino|arm|asp|asymptote|autoconf|autohotkey|autoit|avisynth|awk|bascomavr|basic4gl|bibtex|b3d|blitzbasic|bmx|bnf|boo|bf|c|c_winapi|cpp-winapi|cpp-qt|c_loadrunner|caddcl|cadlisp|ceylon|cfdg|c_mac|chaiscript|chapel|cil|klonec|klonecpp|cmake|cobol|coffeescript|cfm|css|cuesheet|d|dart|dcl|dcpu16|dcs|delphi|oxygene|diff|div|dot|e|ezt|ecmascript|eiffel|epc|euphoria|falcon|filemaker|fo|f1|fortran|freebasic|freeswitch|gambas|gml|gdb|gdscript|genero|genie|gettext|go|godot-glsl|gwbasic|haxe|hicest|hq9plus|html4strict|html5|icon|idl|ini|inno|intercal|io|ispfpanel|j|jcl|jquery|json|julia|Julia|kixtart|ksp|ldif|lb|lsl2|lisp|llvm|locobasic|logtalk|lolcode|lotusformulas|lotusscript|lscript|lua|m68k|magiksf|make|mapbasic|markdown|mercury|metapost|mirc|mmix|mk-61|modula2|modula3|68000devpac|mpasm|mxml|mysql|nagios|netrexx|newlisp|nginx|nim|nsis|oberon2|objeck|objc|ocaml|ocaml-brief|octave|pf|glsl|oorexx|oobas|oracle8|oracle11|oz|parasail|parigp|pascal|pawn|pcre|per|perl|perl6|phix|php-brief|pic16|pike|pixelbender|pli|plsql|postscript|povray|powerbuilder|powershell|proftpd|progress|prolog|properties|providex|purebasic|pycon|python|pys60|q|q/kdb+|qbasic|qml|racket|rails|rbs|rebol|reg|rexx|robots|roff|sas|scheme|scilab|scl|sdlbasic|smalltalk|smarty|spark|sparql|sqf|sql|standardml|StandardML|stonescript|sclang|swift|systemverilog|tsql|tcl|teraterm|texgraph|thinbasic|typoscript|unicon|uscript|upc|urbi|vala|vedit|verilog|vhdl|visualfoxpro|visualprolog|whitespace|whois|winbatch|xbasic|xml|xojo|xorg_conf|xpp|yara|z80|zxbasic) format="$ext" ;;
    esac
fi

filename_encoded="$("$srcdir/urlencode.sh" <<< "$file")"

#content="$("$srcdir/urlencode.sh" <<< "$content" | tr -d '\n')"

{
# try twice, fall back to trying without the API paste format in case it is wrong as this can result in
#
#   Bad API request, invalid api_paste_format
#
command curl -X POST -sSLf https://pastebin.com/api/api_post.php \
     -d "api_option=paste" \
     -d "api_dev_key=$PASTEBIN_API_KEY" \
     -d "api_paste_name=$filename_encoded" \
     -d "api_paste_code=$content" \
     -d "api_paste_expire_date=$expiry" \
     -d "api_paste_private=$private" \
     -d "api_paste_format=$format" ||

    command curl -X POST -sSLf https://pastebin.com/api/api_post.php \
         -d "api_option=paste" \
         -d "api_dev_key=$PASTEBIN_API_KEY" \
         -d "api_paste_name=$filename_encoded" \
         -d "api_paste_code=$content" \
         -d "api_paste_expire_date=$expiry" \
         -d "api_paste_private=$private" ||

        {
            timestamp "FAILED: repeating without the curl -f switch to get the error from the API:"
            command curl -X POST -sSL https://pastebin.com/api/api_post.php \
                 -d "api_option=paste" \
                 -d "api_dev_key=$PASTEBIN_API_KEY" \
                 -d "api_paste_name=$filename_encoded" \
                 -d "api_paste_code=$content" \
                 -d "api_paste_expire_date=$expiry" \
                 -d "api_paste_private=$private"
            echo
            exit 1
        }
} |
tee /dev/stderr |
"$srcdir/copy_to_clipboard.sh"
echo
