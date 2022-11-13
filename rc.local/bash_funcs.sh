#
# These are bash functions that are getting to large to fint in .bashrc
#
source $HOME/lib/bash/bashutils.sh  # error,warning,...

function csvls()
(
    # ls as csv
    # https://stackoverflow.com/questions/14573262/convert-ls-output-into-csv
    find . -ls | awk '{printf( "%s,%s,%s,%s,%s,%s,%s,%s %s %s,%s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11 )}'
)


# Grep out common "junk" files and directories.   Ubuntu/Linux specific.
alias nojunk="egrep -vi \.snap\|\.config\|\.cache\|.git\|.local"

# Find recently modified files or directories
# The intent is to find "things I've been working on recently"

function recentf ()
# find recently modified files
#
# Usage: recentf [DIR [AGE]]
#
#  Defaults: DIR=., AGE=3
{
    # find recently modified files
    #
    # Usage: recentf [directory [days]]

    find ${1:-.} -mtime -${2:-3} -print | \
        nojunk | \
        sort | \
        uniq
}


function recentd ()
{
    # find directories with recently modified files
    #
    # Usage: recentd [directory [days]]

    find ${1:-.} -mtime -${2:-3} -print | \
        nojunk | \
        sed 's#/[^/]*$##' | \
        sort | \
        uniq
}
