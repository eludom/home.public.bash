# These are common functions and settings I use when writing things in bash
# Usage: source $HOME/lib/bash/bashutils.sh

# TODO Make set -u and set -e selectable
#
#   These does not work well in interactive shells.
#
#   Possibly figure out how to detect login/interactive shell
#   and only set if not in login/interactive shell
#


# This is bash.  Be safe.
#set -u
# This causes login shells to exit on error
#
#set -e


ARGV=("$@")
ARGC=("$#")
#ARGV=("${ARGV[@]:1}") # shift ARGV
#ARGC=${#ARGV[@]} # get count

# Helper functions




# Deep bash magic from before the dwan of time...
# https://gitlab.com/kyb/autorsync/-/blob/master/utils.bash#L84

function echodbg  { >/dev/stderr echo $'\e[0;36m'"DBG  $@"$'\e[0m'; }

function stacktrace2 {
   local i=${1:-1} size=${#BASH_SOURCE[@]}
   ((i<size)) && echodbg "STACKTRACE"
   for ((; i < size-1; i++)) ;do  ## -1 to exclude main()
      ((frame=${#BASH_SOURCE[@]}-i-2 ))
      echodbg "[$frame] ${BASH_SOURCE[$i]:-}:${BASH_LINENO[$i]} ${FUNCNAME[$i+1]}()"
   done
}


function stackfuncs {
    # echo stack function list, colon separated, top to bottom in call order

    tracefuncs=""   # stacktrace functions, lowest (in call stack) to hightest

    local i=${1:-1} size=${#BASH_SOURCE[@]}
    #((i<size)) && echodbg "STACKTRACE"
    for ((; i < size-1; i++)) ;do  ## -1 to exclude main()
        ((frame=${#BASH_SOURCE[@]}-i-2 ))
        #echodbg "[$frame] ${BASH_SOURCE[$i]:-}:${BASH_LINENO[$i]} ${FUNCNAME[$i+1]}()"
        tracefuncs="${FUNCNAME[$i+1]}:${tracefuncs}"
        topfunc="${FUNCNAME[$i+1]}"
    done

    tracefuncs=`echo $tracefuncs | sed 's#:$##'`

    echo "${tracefuncs:-unknown}"
}


function info()  { echo `date +%c` `stackfuncs`\: info: "$@" 1>&2; }
function warn()  { echo `date +%c` `stackfuncs`\: warning: "$@" 1>&2; }
function error() { echo `date +%c` `stackfuncs`\: error: "$@" 1>&2; }
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
function debug() { [[ -v DEBUG ]] && echo `date +%c` `stackfuncs`\: debug: "$@" 1>&2 || true ; }
function die()   { echo `date +%c` `stackfuncs`\: fatal: "$@" 1>&2 && exit 1; }

FALSE=1
TRUE=0
