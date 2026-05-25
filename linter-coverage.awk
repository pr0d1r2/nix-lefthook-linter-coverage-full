#!/usr/bin/env -S gawk -f
# Extract backtick-quoted tokens from the first column of each
# markdown table row. Leading `.` is stripped so tokens match the
# output of `sed 's/.*\.//'` over tracked filenames.

/^\|/ {
    col = $0
    sub(/^\|/, "", col)
    end = index(col, "|")
    if (end == 0) next
    col = substr(col, 1, end - 1)
    while (match(col, /`[^`]+`/)) {
        tok = substr(col, RSTART + 1, RLENGTH - 2)
        sub(/^\./, "", tok)
        print tok
        col = substr(col, RSTART + RLENGTH)
    }
}
