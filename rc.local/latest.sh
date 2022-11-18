# shellcheck shell=bash

# shellcheck disable=SC3046 # "source" is more readable than "."
# shellcheck disable=SC1090 # allow source from other locations
# shellcheck disable=SC2112 # "function" is more readable than "()"

# "(" IS valid here.  Function is subshell, own namespace.

# shellcheck disable=SC1036,SC1065,SC1088
function latest ()
{
    (

        # Find lastest modified files[ and grep them].  Because my life is in .org files now...
        #
        # This is really just a wrapper around find -exec grep,
        # but it encapsulates some defaults/patterns I use a lot
        #
        #   - Looking for recently modified (MTIME) files
        #   - Looking at certain types of files (WHAT, e.g. .org)
        #   - Looking in the current directory (WHERE) usually
        #   - Grep(1)ing for file content (GREP)
        #     + sometimes case insensitive
        #     + usually using --color
        #   - Ignoring junk (PRUNE)


        # This is bash.  Be safe.
        # set -u
        # set -e


        # Pull in my logging utils if available
        { test -f ~/lib/bash/bashutils.sh && source ~/lib/bash/bashutils.sh ; } ||
            {
                # fall back to echo
                function info() { echo "$@"; };
                function warn() { echo "$@"; };
                function error() { echo "$@"; };
                function die { echo "$@"; exit 1; };
            }

    #
    # check dependancies
    #

    TIMEOUT=30 # max run at 30 seconds
    which timeout > /dev/null || die "Timeout not found"

    #
    # Defaults for parameters that control find(1)
    #
    WHAT=${WHAT:-org}
    MTIME=${MTIME:-7}
    WHERE=${WHERE:-.}
    # define filenames/paths to be ignored
    #   "junk" stanard on linux systems
    PRUNE_LINUX='/.git/|backups/|auto-save-list|/.config/|snap/|/.cache/|/.local/|/.mozilla/|/.targe|/.rustup/|/.cargo/|/.venv/'
    #   junk specific to me  Your junk milage may vary.
    PRUNE_JUST_ME='blog/docs'
    PRUNE=".*(${PRUNE_JUST_ME}|${PRUNE_LINUX}).*"
    #
    # defaults for parameters that control grep of file content
    #
    REGEX=${REGEX:-}
    GREPCOLOR="always"
    #
    # define errors to be ignored
    #
    # TODO grep out?


    function usage {
        verbosity=${1:-"short"}

        cat <<EOF 1>&2
Usage: latest [options] [WHERE] [MTIME] [[WHAT] REGEX]]
Find the latest files and what's in them.

Options
  -h                   print short help text
     --help            print long help text
  -d|--debug           print debugging

  Find Optons
  -L                   Follow links                Default: Do not follow links.
     --mtime MTIME     Max age of files to find.   Default: $MTIME
  -w|--where DIR       Where to search for files.  Default: $WHERE

  Grep Options
    |--color COLOR     Grep color.                 Default: $GREPCOLOR
                       "always","never", or "auto".
  -i|--ignore-case     Ignore case.                Default: case sensitive.
  -g|--grep REGEX      Regex to grep in files.     Default: None.
  -l|--files-with-matches Only print filename      Default: print match as well.

Arguments
  First one or two positons.
    WHERE           A path (incuding "/").  Overrides -w.
    MTIME           Max age.  Digits.  Overrides --mtime.

  First non-age (digits), non-path (contains "/") argument
    WHAT		Filenames to search for, in full path.  Default: $WHAT

  Second non-age (digits), non-path (contains "/") argument
    REGEX         Regex to grep.  Overrrides -g.
EOF

        if [ "$verbosity" == "long" ]; then
            cat <<EOF2 1>&2

Examples:

# default: find latest .org files in the current directory
$ latest
./test.org

# find org files with an mtime <= 14 days in the current directory
$ latest 14
./test.org
./xxy.org

# Find latest .txt files in current directory
$ latest .txt
./foo.txt

# Find latest .txt files and grep for "baz"
$ latest .txt baz
./foo.txt:foo bar baz
./foo.txt:foo|bar|baz

# Find org files in ~/Org and grep for "DONE"
$ latest ~/Org .org DONE
/home/gmj/Org/agenda-files/blogging.org:**** DONE g/re/p
/home/gmj/Org/agenda-files/blogging.org:**** DONE Write next "40 years of walled garden & open platforms" article
EOF2
        fi

    }

    # Save extra FIND/GREP flags here
    GREPFLAGS=()
    FINDFLAGS=()

    # parse optons
    while [[ $# -gt 0 ]]; do
        case ${1} in
        -h)             usage "short" && return 1;;
            --help)	usage "long" && return 1;;
        -d|--debug)	DEBUG=1 && shift;;

        # Find options
           --mtime)
               shift;
               MTIME="$1"; { { [[ $# -gt 0 ]] && shift; } || die '--mtime requires an argument'; }  ;;
           -w|--where)
               shift;
               WHERE="$1";  { { [[ $# -gt 0 ]] && shift; } || die '--where requires an argument'; }  ;;
           -L)
            shift;
            FINDFLAGS+=("-L");;

        # Grep options
           --color)
            shift;
           GREPCOLOR="${1}";  { { [[ $# -gt 0 ]] && shift; } || die '--color requires an argument'; }  ;;

        -g|--grep)
            shift;
            REGEX="${1}";  { { [[ $# -gt 0 ]] && shift; } || die '--grep requires an argument'; }  ;;
        -i|--ignore-case)
            shift;
            GREPFLAGS+=("-i");;
        -l|--files-with-matches)
            shift;
            GREPFLAGS+=("-l");;
        -*)              error "Unknown flag: $1" && return 1;;
        *)             break;;
       esac
    done

    # parse args


    found_what=false

    while [[ $# -gt 0 ]]; do
        if [[ "$1" = */* ]]; then
            WHERE=$1;
            shift;
        elif [[ "$1" =~ ^[0-9]+$ ]]; then
            MTIME="$1"
            shift
        elif [[ $found_what == true ]]; then
            REGEX="$1";
            shift;
        else
            found_what=true;
            WHAT="$1";
            shift;
        fi

    done

    # Do things to make regular expressions pass down correctly
    #
    #   - ' ' -> '\\s'
    REGEX="${REGEX// /\\s}"

    if [[ $# -gt 0 ]]; then
        die "too many arguments given.  At most 3 allowed.  Unknow: ${ARGV[*]}"
    fi

    if [[ ${REGEX} != "" ]]; then
       GREPFLAGS=("-exec" "grep" "${GREPFLAGS[@]}" "--color=${GREPCOLOR}" "-H ""-E"  "$REGEX" '{}' ';')
   else
       GREPFLAGS=( '-print' )
   fi

    [[ -v DEBUG ]] && set -x

    # this shoud be removed;  If not, find failed/timed out
    RUNNING=$(mktemp /tmp/latest.XXXXXX)

    # Run in a subshell to allow timeout
    ( \
      : COMMENT limit run to TIMEOUT seconds &&\
        timeout $TIMEOUT \
        find \
        ${FINDFLAGS[*]} \
        ${WHERE} \
        \
        $(: COMMENT global options) \
        -regextype posix-extended \
        -xdev \
        \
        $(: COMMENT prune 'junk' files and dirs )\
        -regex "${PRUNE}" -prune -o \
        $(:only look at regular files) \
        -type f \
        \
        $(: COMMENT restrict to mtime MTIME days ag) \
        -mtime -${MTIME}\
        \
        $(:COMMENT restrict to files that match WHAT in full pat) \
        -regex ".*${WHAT}.*" \
        \
        $(:COMMENTrun grep if request) \
        ${GREPFLAGS[*]} && \
        \
        $(: COMMENT If find finished, remove RUNNING file.  Timeout will leave it) \
         \rm -f $RUNNING \
        ) \
        # |& grep -v -E ': Permission|: Too many levels'

    if [[ -f "${RUNNING}" ]]; then
        warn "Find did not finish.  Timeout or error";
        \rm ${RUNNING}
    fi

    [[ -v DEBUG ]] && set +x
)} # function
