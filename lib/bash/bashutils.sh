# These are common functions and settings I use when writing things in bash
#
# Usage: source $HOME/lib/bash/bashutils.sh
set -e; set -u

ARGV=("$@")
ARGC=("$#")
#ARGV=("${ARGV[@]:1}") # shift ARGV
#ARGC=${#ARGV[@]} # get count

# Helper functions


# TODO improve use of func
#      - "bash"        ::  if just called from shell
#      - $0            ::  if just in the name body of a script
#      - $0:$FUNCNAME  ::  if in a function

if [[ -v 0 ]]; then
    if [[ "$0" == "-bash" ]]; then
        PROG="bash"
    else
        PROG=`basename "$0" | tr -d '\n'`
    fi
else
    PROG="unknown"
fi


function info()  { echo `date +%c` ${PROG}\: info: "$@" 1>&2; }
function warn()  { echo `date +%c` ${PROG}\: warning: "$@" 1>&2; }
function error() { echo `date +%c` ${PROG}\: error: "$@" 1>&2; }
# Temporary debug messages
#   DEBUG=1 debug foo
#
# GLobal debug messages
#   export DEBUG=1
#   ...
#   debug foo
#
# TODO
#   have it check debug levels and or strings
function debug() { [[ -v DEBUG ]] && echo `date +%c` ${PROG}\: debug: "$@" 1>&2 || true ; }
function die()   { echo `date +%c` ${PROG}\: fatal: "$@" 1>&2 && exit 1; }
