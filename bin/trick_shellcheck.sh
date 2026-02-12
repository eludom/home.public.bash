#! /bin/bash
# "fix" things shellcheck refuses to ignore
#
# shellcheck refuses to ignore some bash syntax
# that is perfeclty valid.   This fixes them to  pass tests.
#
# Uasge:
#
#  cat FOO.sh | trick_shellcheck | shellcheck -

: replace
:   "function FOO ("
: with
:   "function FOO {"
sed 's#\(function .* \)[(]#\1 {#' | \
sed 's/) # function/} # function/'
