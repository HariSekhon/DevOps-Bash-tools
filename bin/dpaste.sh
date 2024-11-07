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
Uploads a file to https://dpaste.com and copies the resulting URL to your clipboard

Prompts to confirm the content before uploading for your safe review as this is PUBLIC

Expiry defaults to 1 day

Recommended: use anonymize.py or anonymize.pl from the adjacent DevOps-Python-tools or DevOps-Perl-tools repos

Optional: decomment.sh

Syntax Highlighting: tries to auto-infer it in this script for some common formats based on the file extension.
                     You can override this as an argument

See values for syntax highlighting here:

    https://dpaste.com/syntaxes/

Knowledge Base page: https://github.com/HariSekhon/Knowledge-Base/blob/main/upload-sites.md
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename> [<expiry> <format>]"

help_usage "$@"

min_args 1 "$@"

file="$1"
expiry="${2:-${DPASTE_EXPIRY:-1}}"
format="${3:-text}"  # syntax highlighting

if ! [[ "$expiry" =~ ^[[:digit:]]$ ]]; then
    usage "Invalid value for expiry arg, must be an integer of days"
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
Here is what will be dpaste-ed:

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
    #   https://dpaste.com/api/syntax-choices/
    #
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
        psql) format=psql ;;
        postgres | postgresql) format=postgresql ;;
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
        vb) format=vb.net ;;
        vbs | vbscript) format=vbscript ;;
        vim | vimscript) format=vim ;;
        yml | yaml) format=yaml ;;
        # the rest try for straight matches - some of these should probably be moved above with more file extension variations
        #
        # Populated from:
        #
        #   curl https://dpaste.com/api/syntax-choices/ | jq -r 'keys[]' | tr '\n' '|'
        abap|abnf|actionscript3|ada|adl|agda|aheui|alloy|ambienttalk|amdgpu|ampl|ansys|antlr|antlr-actionscript|antlr-cpp|antlr-csharp|antlr-java|antlr-objc|antlr-perl|antlr-python|antlr-ruby|apacheconf|apl|applescript|arduino|arrow|arturo|asc|asn1|aspectj|aspx-cs|aspx-vb|asymptote|augeas|autohotkey|autoit|awk|bare|basemake|batch|bbcbasic|bbcode|bc|bdd|befunge|berry|bibtex|blitzbasic|blitzmax|blueprint|bnf|boa|boo|boogie|bqn|brainfuck|bst|bugs|c|c-objdump|ca65|cadl|camkes|capdl|capnp|carbon|cbmbas|cddl|ceylon|cfc|cfengine3|cfm|cfs|chaiscript|chapel|charmci|cheetah|cirru|clay|clean|clojure|clojurescript|cmake|cobol|cobolfree|coffeescript|comal|common-lisp|componentpascal|console|coq|cplint|cpp-objdump|cpsa|cr|crmsh|croc|cryptol|csharp|csound|csound-document|csound-score|css|css+django|css+genshitext|css+lasso|css+mako|css+mozpreproc|css+myghty|css+php|css+ruby|css+smarty|css+ul4|cuda|cypher|cython|d|d-objdump|dart|dasm16|dax|debcontrol|debsources|delphi|desktop|devicetree|dg|diff|django|docker|doscon|dpatch|dtd|duel|dylan|dylan-console|dylan-lid|earl-grey|easytrieve|ebnf|ec|ecl|eiffel|elixir|elm|elpi|emacs-lisp|erb|erl|erlang|evoque|execline|extempore|ezhil|factor|fan|fancy|felix|fennel|fift|fish|flatline|floscript|forth|fortran|fortranfixed|foxpro|freefem|fsharp|fstar|func|futhark|gap|gap-console|gas|gcode|gdscript|genshi|genshitext|gherkin|glsl|gnuplot|go|golo|gooddata-cl|gosu|graphql|graphviz|groff|gsql|gst|haml|handlebars|haskell|haxe|haxeml|hexdump|hlsl|hsail|hspec|html|html+cheetah|html+django|html+evoque|html+genshi|html+handlebars|html+lasso|html+mako|html+myghty|html+ng2|html+php|html+smarty|html+twig|html+ul4|html+velocity|http|hybris|hylang|i6t|icon|idl|idris|iex|igor|inform6|inform7|ini|io|ioke|irc|isabelle|j|jags|jasmin|javascript+cheetah|javascript+django|javascript+lasso|javascript+mako|javascript+mozpreproc|javascript+myghty|javascript+php|javascript+ruby|javascript+smarty|jcl|jlcon|jmespath|js+genshitext|js+ul4|jsgf|jslt|json|jsonld|jsonnet|jsp|jsx|julia|juttle|k|kal|kconfig|kmsg|koka|kotlin|kql|kuin|lasso|ldapconf|ldif|lean|less|lighttpd|lilypond|limbo|liquid|literate-agda|literate-cryptol|literate-haskell|literate-idris|livescript|llvm|llvm-mir|llvm-mir-body|logos|logtalk|lsl|lua|macaulay2|make|mako|maql|mask|mason|mathematica|matlab|matlabsession|maxima|mcfunction|mcschema|meson|mime|minid|miniscript|mips|modelica|modula2|monkey|monte|moocode|moonscript|mosel|mozhashpreproc|mozpercentpreproc|mql|mscgen|mupad|mxml|myghty|mysql|nasm|ncl|nemerle|nesc|nestedtext|newlisp|newspeak|ng2|nginx|nimrod|nit|nixos|nodejsrepl|notmuch|nsis|numpy|nusmv|objdump|objdump-nasm|objective-c|objective-c++|objective-j|ocaml|octave|odin|omg-idl|ooc|opa|openedge|openscad|output|pacmanconf|pan|parasail|pawn|peg|perl|perl6|phix|pig|pike|pkgconfig|plpgsql|pointless|pony|portugol|postgres-explain|postscript|pot|pov|powershell|praat|procfile|prolog|promql|properties|protobuf|prql|psysh|ptx|pug|puppet|pwsh-session|py+ul4|py2tb|pycon|pypylog|pytb|python|python2|q|qbasic|qlik|qml|qvto|racket|ragel|ragel-c|ragel-cpp|ragel-d|ragel-em|ragel-java|ragel-objc|ragel-ruby|rbcon|rconsole|rd|reasonml|rebol|red|redcode|registry|resourcebundle|rexx|rhtml|ride|rita|rng-compact|roboconf-graph|roboconf-instances|robotframework|rql|rsl|rst|rust|sarl|sas|sass|savi|scaml|scdoc|scheme|scilab|scss|sed|sgf|shen|shexc|sieve|silver|singularity|slash|slim|slurm|smali|smalltalk|smarty|smithy|sml|snbt|snobol|snowball|solidity|sophia|sp|sparql|spice|splus|sql|sql+jinja|sqlite3|squidconf|srcinfo|ssp|stan|stata|supercollider|swift|swig|systemd|systemverilog|tads3|tal|tap|tasm|tcl|tcsh|tcshcon|tea|teal|teratermmacro|termcap|terminfo|terraform|text|thrift|ti|tid|tlb|tls|tnt|todotxt|toml|trac-wiki|trafficscript|treetop|tsql|turtle|twig|typoscript|typoscriptcssdata|typoscripthtmldata|ucode|ul4|unicon|unixconfig|urbiscript|usd|vala|vcl|vclsnippets|vctreestatus|velocity|verifpal|verilog|vgl|vhdl|visualprolog|visualprologgrammar|vyper|wast|wdiff|webidl|wgsl|whiley|wikitext|wowtoc|wren|x10|xml|xml+cheetah|xml+django|xml+evoque|xml+lasso|xml+mako|xml+myghty|xml+php|xml+ruby|xml+smarty|xml+ul4|xml+velocity|xorg.conf|xpp|xquery|xslt|xtend|xul+mozpreproc|yaml+jinja|yang|yara|zeek|zephir|zig|zone) format="$ext" ;;
    esac
fi

#filename_encoded="$("$srcdir/urlencode.sh" <<< "$file")"

#content="$("$srcdir/urlencode.sh" <<< "$content" | tr -d '\n')"

{
# try twice, fall back to trying without the API syntax highlighting selection in case it is wrong as this can result in
#
command curl -sSLf https://dpaste.com/api/v2/ \
             -F "expiry_days=$expiry" \
             -F "syntax=$format" \
             -F "content=<-" <<< "$content" ||

    command curl -sSLf https://dpaste.com/api/v2/ \
                 -F "expiry_days=$expiry" \
                 -F "content=<-" <<< "$content" ||

        {
            timestamp "FAILED: repeating without the curl -f switch to get the error from the API:"
            command curl -sSL https://dpaste.com/api/v2/ \
                         -F "expiry_days=$expiry" \
                         -F "content=<-" <<< "$content"
            echo
            exit 1
        }
} |
tee /dev/stderr |
"$srcdir/copy_to_clipboard.sh"
echo
