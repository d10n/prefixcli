# prefixcli

Prefix / prepend a string to CLI command output

Sometimes in long-running output of a CLI command I want to prefix every line with a string.
For example, timestamps on lines of a system update, timestamps on lines of a deploy, or the name of the current task being run in a list of tasks.

There is not an existing simple tool or one-liner I could find to do this already. The sed/awk/perl/ruby one-liners like ` | sed "s/^/$PREFIX /"` break down on progress bars made with carriage return.

prefixcli partially solves the progress bar problem because it properly handles `\r`.

The source has ugly comments while I figure nim stuff out.

## Caveats

When a CLI progress bar is programmed to fill all columns of the tty, prefixcli overflows the line, causing a new line to be rendered for each update to the progress bar. This could be fixed by altering the tty width (use isatty, ioctl, TIOCGWINSZ, ITOCSWINSZ or shell out to stty)
https://nim-lang.org/docs/terminal.html#TerminalCmd

## Performance

    user@host:~/code/prefixcli
    $ timeout 5 yes | pv -a >/dev/null
    [5.74GiB/s]
    user@host:~/code/prefixcli
    $ timeout 5 yes | ./bin/prefixcli | pv -a >/dev/null
    [28.2MiB/s]
    user@host:~/code/prefixcli
    $

## Testing

Manual testing for now:

    ./scripts/generate-test-output.sh | ./bin/prefixcli
    ./scripts/generate-test-output.sh | ./bin/prefixcli 'hello world'
    ./scripts/generate-test-output.sh | ./bin/prefixcli --sep=''
    ./scripts/generate-test-output.sh | ./bin/prefixcli --sep=' : '
    ./scripts/generate-test-output.sh | ./bin/prefixcli --eval 'HI=hi; echo $HI'
    ./scripts/generate-test-output.sh | pv --rate-limit=3 --quiet | ./bin/prefixcli

## TODO

* Suppress traceback on SIGINT etc.
* Address tty caveat

## Alternatives

 * ` | sed "s/^/$PREFIX /"`
 * ` | awk -v prefix="$PREFIX" '{ print prefix $0 }'`
 * ` | ruby -e 'prefix="PREFIX ";print prefix; while (s=gets(4)); print s.gsub(/[\r\n]/,"\\0#{prefix}"); end'`
    * `gets()` interferes with being able to pass the prefix in as an argument