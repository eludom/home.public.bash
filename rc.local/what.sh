function what () {
    # Show what command will run when $1 is typed
    if [ $# -ne 1 ]; then
        echo "$FUNCNAME: Usage: $FUNCNAME COMMAND|--help" 1>&2
        return
    fi

    if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "help" ]; then
        echo "$FUNCNAME: Show what command will run when $1 is typed"
        echo "$FUNCNAME: Bash executes aliases, functiions and binaries on path, in that order"
        echo "$FUNCNAME: Usage: $FUNCNAME COMMAND" 1>&2
        return
    fi

    echo FOO
    alias | grep -i "alias $1=" || \
        declare -f $1 || \
        compgen -b $1 || \
        which $1 || \
        echo "$FUNCNAME: $1 is unknown. Not on path, an alais, builtin or a function" 1>&2
}
