#
# These are bash functions that are getting to large to fint in .bashrc
#
source $HOME/lib/bash/bashutils.sh  # error,warning,...

function gf() ( # function in subshell, own namespece.

    regex="${1:-NONE}"
    arg1="${regex}"
    files="${2:-'*.org'}"
    days="${3:-7}"

    function usage ()  {

        message=${1:-""}

        cat <<EOF 1>&2
Usage: $0 [options] regex [files [days]]

gf (grep find) performs grep on the results find for a given number of days

-h| --help           print help text

regex                regex to serach for
files                files to serach
days                 how many days back (mtime) to search

Examples:
  gf findMeAnywhere
  gf findMeInTextFiles '*.txt'
  gf findMeInTextFiles .txt
  gf BEGIN\|END .org 7
EOF


        if [[ "${message}" != "" ]]; then
           echo 2>&1
           error "${message}"
        fi
    }

    set -o noglob

    case $arg1 in
        NONE)		usage "Missing regex" && return 1;;
        -h|--help)	usage && return 1;;
    esac

    # Second arg is files for find.  No globbing, so "*.txt" OK
    if [[ "$files" =~ ^\. ]]; then
        # Special case: treat ".foo" as "*.foo"
        # Avoids needing to quote on command line
        files_flag="-name *$files"
    else
        files_flag="-name ${files}"
    fi

    cmd="find . -type f -mtime -${days} $files_flag -exec egrep --color=always -H -i ${regex} {} ;"
    debug "command: ${cmd}"
    
    (exec $cmd)

)
