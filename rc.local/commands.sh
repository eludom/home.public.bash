function commands () {
    # list all aliases, functions, builtins and binaries on path
    # https://stackoverflow.com/questions/64363600/bash-search-order-among-aliases-functions-binaries
    # https://unix.stackexchange.com/questions/120786/list-all-binaries-from-path

    compgen -a # aliases
    compgen -A function # functions
    compgen -b # builtins
    compgen -k # keywords
    compgen -c # binaries on path
}
