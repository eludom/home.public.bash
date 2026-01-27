# Usage: latest [options] [WHERE]
#
# Find lastest modified files[ and grep them].
# Because my life is in .org files now...
#
# This is really just a wrapper around find -exec grep,
# but it encapsulates some defaults/patterns I use a lot
#
#   - Looking for .org files (default)
#   - Looking for recently modified (MTIME) files
#   - Looking for other types of files (FILENAMES, e.g. .txt)
#   - Looking in the current directory (WHERE) usually
#   - Grep(1)ing for file content (GREP)
#     + sometimes case insensitive
#     + usually using --color
#   - Ignoring junk (PRUNE)

#
# This is bash, be safe
#
# shellcheck shell=bash
# shellcheck disable=SC3046 # "source" is more readable than "."
# shellcheck disable=SC1090 # allow source from other locations
# shellcheck disable=SC2112 # "function" is more readable than "()"

# shellcheck disable=SC1036,SC1065,SC1088
function latest ()
{
    (



        # This is bash.  Be safe.
        set -u
        set -e
        # These are running in the context of the subshell
        # so they will not affect the parent (login) shell
        # but will give us extra checks/safety.


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


    #
    # Defaults for parameters that control find(1)
    #
    FILENAMES=${FILENAMES:-org$}
    MTIME=${MTIME:-7}
    WHERE=${WHERE:-.}
    TIMEOUT=30 # max run at 30 seconds
    FIND_REGEX="-regex" # case sensitive by default
    which timeout > /dev/null || die "Timeout not found"

    # define filenames/paths to be ignored
    #   "junk" stanard on linux systems
    PRUNE_LINUX='/.git/|backups/|auto-save-list|/.config/|snap/|/.cache/|/.local/|/.mozilla/|/.targe|/.rustup/|/.cargo/|/.venv/'
    #   junk specific to me  Your junk milage may vary.
    PRUNE_JUST_ME='blog/docs|orgfiles|stow|backups'
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
Usage: latest [options] [WHERE]
Find the latest files and what's in them.

Options
  -h                   print short help text
     --help            print long help text
  -d|--debug           print debugging
  -t|--timeout TIMEOUT Timeout find command        Default: $TIMEOUT

  Find Options
  -P|--no-follow       Do not follow symlinks      Default: Follow symlinks.
  -m|--mtime MTIME     Max age of files to find.   Default: $MTIME
                       0 means "forever"
  -f|--files PATTERN   Filename pattern to match.  Default: $FILENAMES

  Grep Options
     --color COLOR     Grep color.                 Default: $GREPCOLOR
                       "always","never", or "auto".
  -i|--ignore-case     Ignore case.                Default: case sensitive.
  -g|--grep REGEX      Regex to grep in files.     Default: None.
  -l|--files-with-matches Only print filename      Default: print match as well.

Arguments
  WHERE                Directory to search.        Default: $WHERE
EOF

        if [ "$verbosity" == "long" ]; then
            cat <<EOF2 1>&2

Examples:

# default: find latest .org files in the current directory
$ latest
./test.org

# find org files with an mtime <= 14 days in the current directory
$ latest -m 14
./test.org
./xxy.org

# Find latest .txt files in current directory
$ latest -f '.txt$'
./foo.txt

# Find latest .txt files and grep for "baz"
$ latest -f '.txt$' -g baz
./foo.txt:foo bar baz
./foo.txt:foo|bar|baz

# Find org files in ~/Org and grep for "DONE"
$ latest -g DONE ~/Org
/home/gmj/Org/agenda-files/blogging.org:**** DONE g/re/p
/home/gmj/Org/agenda-files/blogging.org:**** DONE Write next "40 years of walled garden & open platforms" article

# Find the lastest .org and py files, 120 days old or less
$ latest -m 120 -f '(\.py$|\.org$)'

# Grep for a pattern with "/" in it
$ latest -g 'notes/gpt' ~/
EOF2
        fi

    }

    # Save extra FIND/GREP flags here
    GREPFLAGS=()
    FINDFLAGS=("-L")  # Follow symlinks by default

    # parse optons
    while [[ $# -gt 0 ]]; do
        case ${1} in
        -h)             usage "short" && return 1;;
            --help)	usage "long" && return 1;;
        -d|--debug)	DEBUG=1 && shift;;
        -t|--timeout)
               shift;
               TIMEOUT="$1";  { { [[ $# -gt 0 ]] && shift; } || die '--timeout requires an argument'; }  ;;

        # Find options
           -m|--mtime)
               shift;
               MTIME="$1"; { { [[ $# -gt 0 ]] && shift; } || die '--mtime requires an argument'; }  ;;
           -f|--files)
               shift;
               FILENAMES="$1"; { { [[ $# -gt 0 ]] && shift; } || die '--files requires an argument'; }  ;;
           -w|--where)
               shift;
               WHERE="$1";  { { [[ $# -gt 0 ]] && shift; } || die '--where requires an argument'; }  ;;
           -P|--no-follow)
            shift;
            FINDFLAGS=();;

        # Grep options
           --color)
            shift;
           GREPCOLOR="${1}";  { { [[ $# -gt 0 ]] && shift; } || die '--color requires an argument'; }  ;;

        -g|--grep)
            shift;
            REGEX="${1}";  { { [[ $# -gt 0 ]] && shift; } || die '--grep requires an argument'; }  ;;
        -i|--ignore-case)
            shift;
            FIND_REGEX="-iregex"
            GREPFLAGS+=("-i");;
        -l|--files-with-matches)
            shift;
            GREPFLAGS+=("-l");;
        -*)              error "Unknown flag: $1" && return 1;;
        *)             break;;
       esac
    done

    # parse positional args - only WHERE is accepted
    if [[ $# -gt 1 ]]; then
        die "Too many arguments. Only WHERE is accepted as positional argument. Use flags for other options."
    fi

    if [[ $# -eq 1 ]]; then
        WHERE="$1"
        debug WHERE is $WHERE
    fi

    if test "$MTIME" = 0; then MTIME=999999; fi

    # Do things to make regular expressions pass down correctly
    #
    #   - ' ' -> '\\s'
    REGEX="${REGEX// /\\s}"


    if [[ ${REGEX} != "" ]]; then
       GREPFLAGS=("-exec" "grep" "${GREPFLAGS[@]}" "--color=${GREPCOLOR}" "-H ""-E"  "$REGEX" '{}' ';')
   else
       GREPFLAGS=( '-print' )
   fi

    [[ -v DEBUG ]] && set -x

    # this shoud be removed;  If not, find failed/timed out
    RUNNING=$(mktemp /tmp/latest-running.XXXXXX)


# shellcheck disable=SC2046 # Quote this to prevent word splitting.
#
#   This is to all the
#
#     $(: COMMENT comments here)
#
#   syntax work without warning.

    # Run in a subshell to allow timeout
    ( \
        $(: COMMENT limit run to "$TIMEOUT" seconds) \
        timeout "$TIMEOUT" \
        find \
        "${FINDFLAGS[@]}" \
        "${WHERE}" \
        \
        $(: COMMENT global options) \
        -regextype posix-extended \
        -xdev \
        \
        $(: COMMENT prune 'junk' files and dirs: "${PRUNE}" )\
        -regex "${PRUNE}" -prune -o \
        $(: only look at regular files) \
        -type f \
        \
        $(: COMMENT restrict to mtime "$MTIME" days ago) \
        -mtime -"${MTIME}"\
        \
        $(: COMMENT restrict to files that match "$FILENAMES" in full pat) \
        ${FIND_REGEX} ".*${FILENAMES}.*" \
        \
        $(: COMMENT run grep if requested: "${GREPFLAGS[*]}") \
        ${GREPFLAGS[*]} && \
        \
        $(: COMMENT If find finished, remove RUNNING file "${RUNNING}".  Timeout will leave it) \
         /bin/rm -f "$RUNNING" \
        ) \
        # |& grep -v -E ': Permission|: Too many levels'

# shellcheck enable=quote-safe-variables

    if [[ -f "${RUNNING}" ]]; then
        warn "Find did not finish.  Timeout or error";
        \rm "${RUNNING}"
    fi

    [[ -v DEBUG ]] && set +x
)}

# "see" where something is
alias see=latest
