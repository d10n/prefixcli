#!/bin/bash
(
line() {
    printf "$1"
    perl -e 'select(undef, undef, undef, 0.5)'
}
line "\n"
line 'h'
line "\rhe"
echo my-error-1 >&2
line "\rhel"
line "\n"
line "hello\n"
line "hello world\n"
line "he"
line "\rhello"
echo my-error-2 >&2
line "\rhel"
line "\rfoo"
line "\rfoobar\n"
line "fooobar\n"
line "\n"
)
