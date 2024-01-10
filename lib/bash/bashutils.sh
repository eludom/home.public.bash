# These are common functions and settings I use when writing things in bash
# Usage: source $HOME/lib/bash/bashutils.sh
#
# Imports (optional)
#   Set these to control behavior
#
#   # print debug messages
#   export DEBUG=1
#
#   # set explicit program name
#   export PROGNAME=foo
#
#   # choose descriptor to use for error messages
#   export ERROR_FD=1 # stdout
#   export ERROR_FD=2 # stderr
#
#   # choose not to use -u and -e
#   export NO_ERRORS=1
#
# Exports:
#   These are defined and exported
#
#  ARGV=("$@")
#  ARGC=("$#")
#  FALSE=1
#  TRUE=0


# Set -u and -e unless in interative shell or NO_ERRORS set.

if [[ $- == *i* ]]; then
  IS_INTERACTIVE=1
fi

if [ "$SHLVL" -eq 1 ]; then
      IS_LOGIN=1
fi

if [ -n "${IS_INTERACTIVE+xxx}" ] || [ -n "${IS_LOGIN+xxx}" ]; then
    # These does not work well in interactive shells.
    :
elif [ -z "${NO_ERRORS+xxx}" ]; then
   # This is bash.  Be safe.
   set -u -e
fi


# exports
ARGV=("$@")
ARGC=("$#")
FALSE=1
TRUE=0

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

    default_name="${PROGNAME:-default}"

    echo "${tracefuncs:-$default_name}"
}



function info()  { echo `date +%c` `stackfuncs`\: info: "$@" >&${ERROR_FD:-2}; }
function warn()  { echo `date +%c` `stackfuncs`\: warning: "$@" >&${ERROR_FD:-2}; }
function error() { echo `date +%c` `stackfuncs`\: error: "$@" >&${ERROR_FD:-2}; }
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
function debug() { [[ -v DEBUG ]] && echo `date +%c` `stackfuncs`\: debug: "$@" >&${ERROR_FD:-2} || true ; }
function die()   {

    exit_code=1
    if [[ -v 2 ]]; then
       exit_code="${1}"
       shift;
    fi

    echo `date +%c` `stackfuncs`\: fatal: "$@" >&${ERROR_FD:-2} && exit "${exit_code}";
}
