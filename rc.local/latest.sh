function latest (
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

    # Define some logging aliases
    source ~/lib/bash/bashutils.sh || `: # Use my library if available`\
    `: fall back to echo`
    alias info=echo && \
    alias warn=echo && \
    alias error=echo

    #
    # Defaults for parameters that control find(1)
    #
    WHAT=${WHAT:-org}
    MTIME=${MTIME:-7}
    WHERE=${WHERE:-.}
    # define filenames/paths to be ignored
    #   "junk" stanard on linux systems
    PRUNE_LINUX='git/|backups/|auto-save-list|config/|snap/|cache/|local/|mozilla/|target/|.rustup/|.cargo/'
    #   junk specific to me  Your junk milage may vary.
    PRUNE_JUST_ME='blog/docs'
    PRUNE=".*(${PRUNE_JUST_ME}|${PRUNE_LINUX}).*"
    #
    # defaults for parameters that control grep of file content
    #
    GREP=${GREP:-}
    #
    # define errors to be ignored
    #
    # TODO grep out?


    function usage ()  {
        message=${1:-""}
        cat <<EOF 1>&2
Usage: latest [options] [WHERE] [MTIME] [[WHAT] REGEX]]

       find the latest files and what's in them.

Options
  -h|--help            print help text
  -d|--debug           print debugging

  Find Optons
     --mtime=MTIME     Max age of files to find.   Default: $MTIME
  -w|--where=DIR       Where to search for files.  Default: $WHERE

  Grep Options
  -i|--ignore-case     Ignore case.                Default: case sensitive.
  -g|--grep=REGEX      Regex to grep in files.     Default: None.


Arguments
  First one or two positons.
    WHERE           A path (incuding "/").  Overrides -w.
    MTIME           Max age.  Digits.  Overrides --mtime.

  First non-age (digits), non-path (contains "/") argument
    WHAT		Filenames to search for, in full path.  Default: $WHAT

  Second non-age (digits), non-path (contains "/") argument
    REGEX         Regex to grep.  Overrrides -g.

Examples:
  # find latest .org files in current directorry
    lastest

  # find .sql files modified in the last 30 days in the home directory
    latest -a 30 -w $HOME sql
      or
    latest 30 $HOME sql

  # find python files with "pandas"
    latest -g pandas .py
      or
    latest .py pandas


EOF

    }

    # Save extra FIND/GREP flags here
    FINDFLAGS=()
    GREPFLAGS=()

    # parse optons
    while [[ $# > 0 ]]; do
        case ${1} in
        -h|--help)	usage && return 1;;
        -d|--debug)	DEBUG=1 && shift;;

        # Fine opions
           --mtime)
               shift;
               MTIME="$1"; [[ $# > 0 ]] && shift || die '--age requires an argument';;
           -w|--where)
               shift;
               WHERE="$1" && shift || die '--where requires an argument';;

        # Grep options
        -g|--grep)
            shift;
            REGEX="${1}" && shift || die '--grep requires an argument';
            ;;
        -i|--ignore-case)
            shift;
            GREPFLAGS+=("-i");;
        -*)              error "Unknown flag: $1" && return 1;;
        *)             break;;
       esac
    done

    # parse args


    found_what=false
    found_regex=false

    while [[ $# > 0 ]]; do
        if [[ "$1" = */* ]]; then
            WHERE=$1;
            shift;
        elif [[ "$1" =~ ^[0-9]+$ ]]; then
            MTIME="$1"
            shift
        elif [[ $found_what == true ]]; then
            REGEX="$1";
            found_regex=true;
            shift;
        else
            found_what=true;
            WHAT="$1";
            shift;
        fi

    done

    # Do things to make regular expressions pass down correctly
    #
    # echo REGEX before regex fixes '>'$REGEX'<'
    #   - ' ' -> '\\s'
    REGEX=`echo "$REGEX" | sed 's# #\\\s#g'`
    # echo REGEX after regex fixes '>'$REGEX'<'

    if [[ $# > 0 ]]; then
        die "too many arguments given.  At most 3 allowed.  Unknow: ${ARGV[*]}"
    fi

    if [[ ${REGEX} != "" ]]; then
       GREPFLAGS=("-exec" "grep" ${GREPFLAGS[@]} "--color=always" "-H ""-E"  "$REGEX" '{}' ';')
   else
       GREPFLAGS=( '-print' )
   fi

   [[ -v DEBUG ]] && set -x

   find -L ${WHERE} \
        `: global options` \
        `: prune 'junk' files and dirs` \
        -regextype posix-extended \
        -xdev \
        -regex "${prune}" -prune -o \
        `: only look at regular files ` \
        -type f \
        `: restrict to mtime MTIME days ago` \
        -mtime -${MTIME}\
        `: restrict to files that match WHAT in full path` \
        -regex ".*${WHAT}.*" \
        ${GREPFLAGS[*]}

    [[ -v DEBUG ]] && set +x
)
