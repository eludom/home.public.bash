function count () (
    # count uniq lines on stdin, sort results

    uniq -c | sort -nr
)
