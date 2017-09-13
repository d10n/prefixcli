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

progressline() {
    width=$(tput cols)
    percent="$1"
    filled=$(( width * percent / 100 ))
    remainder=$(( width - filled ))
    perl -e 'printf("\r"."#" x $ARGV[0] . "-" x $ARGV[1]);
        select(undef, undef, undef, 0.25)' $filled $remainder
}
printf "\n"
progressline 0
progressline 10
progressline 20
progressline 30
progressline 40
progressline 50
progressline 60
progressline 70
progressline 80
progressline 90
progressline 100
printf "\n"
)
