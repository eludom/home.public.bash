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

function csvls()
(
    # ls as csv
    # https://stackoverflow.com/questions/14573262/convert-ls-output-into-csv
    find . -ls | awk '{printf( "%s,%s,%s,%s,%s,%s,%s,%s %s %s,%s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11 )}'
)

# Find recently modified files or directories
# The intent is to find "things I've been working on recently"

function recentf ()
{
    # find recently modified files
    #
    # Usage: recentf [days [dirctory]]

    find ${2:-.} -mtime -${1:-3} -print | \
        egvi \.git | \
        sort | \
        uniq
}


function recentd ()
{
    # find directories with recently modified files
    #
    # Usage: recentd [days [dirctory]]

    find ${2:-.} -mtime -${1:-3} -print | \
        egvi \.git | \
        sed 's#/[^/]*$##' | \
        sort | \
        uniq
}
