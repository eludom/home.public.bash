# define where() function to tell where a command/alias/function is defined

source $HOME/lib/bash/bashutils.sh  # error,warning,...

ARGV=("$@")
ARGC=("$#")


function where() ( # function in subshell, own namespece.

    export PROG="$FUNCNAMEo"
    ARG1="${1:-NONE}"
    ARG2="${2:-NONE}"

    function usage ()  {

        message=${1:-""}

        cat <<EOF 1>&2
Usage: $0 [options] command

Show WHERE a command is defined (which BINARY, alias FOO, function FOO)

-h| --help           print help text

command              this is the name of the command, alias, function, etc.

Examples:
  where ls
  where myalias
  where myfunction
EOF


        if [[ "${message}" != "" ]]; then
           echo 2>&1
           error "${message}"
        fi
    }

    case $ARG1 in
        NONE)		usage "Missing argument.  Need name of command." && return 1;;
        -d|--debug)	DEBUG=1 && shift;;
        -h|--help)	usage && return 1;;
    esac


    if [[ $# != 1 ]]; then
        usage "Expecting one arguemt, got $#: $*  " && return 1;
    fi
    
    [[ -v DEBUG ]] && set -x

    case "`type -t $1`" in
        alias|file)
            type $1;
            ;;
        function)
            # Enable debugging
            #
            #   shopt -s extdebug
            #
            # to get file names and line nmbers
            shopt -s extdebug
            shopt -q extdebug && declare -Ff $1 || echo $1 is a functon 
            ;;
        *)
            type -t $1 || warn "$1 is not defined";
            ;;
    esac

)

function there() {
    where
}
