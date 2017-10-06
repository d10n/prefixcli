#!/bin/bash
(
line() {
    printf "$1"
    perl -e 'select(undef, undef, undef, 0.25)'
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

progressbar1() {
    for i in $(seq 0 10 100); do
        percent="$i"
        width=$(( $(tput cols) - 6 ))
        filled=$(( width * percent / 100 ))
        remainder=$(( width - filled ))
        perl -e 'printf("\r"."#" x $ARGV[0] . "-" x $ARGV[1] . $ARGV[2]);
            select(undef, undef, undef, 0.25)' $filled $remainder "$(printf ' %3d%%' $percent)"
    done
    printf "\n"
}
progressbar2() {
    line "::::::::::\r"
    for i in $(seq 10); do
        line '#'
    done
    printf "\n"
}
printf "Progress bar type 1:\n"
progressbar1
printf "Progress bar type 2:\n"
progressbar2
printf "\n"
)
