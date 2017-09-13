# prefixcli

Prefix / prepend a string to CLI command output

Sometimes in long-running output of a CLI command I want to prefix every line with a string.
For example, timestamps on lines of a system update, timestamps on lines of a deploy, or the name of the current task being run in a list of tasks.

There is not an existing simple tool or one-liner I could find to do this already. The sed/awk/perl/ruby one-liners like ` | sed "s/^/$PREFIX /"` break down on progress bars made with carriage return.

prefixcli partially solves the progress bar problem because it properly handles `\r`.

The source has ugly comments while I figure nim stuff out.

## Caveats / TODO

 * Some progress bars get disabled because there is no pty.  
   Make a pty to handle those. (posix_openpt)  
   **Workaround**: Use `unbuffer` (part of the `expect` package) like in the example below
 * Lines on stderr are ignored (not prefixed) by default.  
   **Workaround**: If you want to prefix every line, redirect stderr to stdout with `2>&1` like in the example below

## Performance

    user@host:~/code/prefixcli
    $ timeout 5 yes | pv -a >/dev/null
    [5.74GiB/s]
    user@host:~/code/prefixcli
    $ timeout 5 yes | ./bin/prefixcli | pv -a >/dev/null
    [58.8MiB/s]

## Compiling / building

Run `nimble build`.

A Dockerfile is provided for easy repeatable statically linked Linux builds:

    docker build -t prefixcli .
    docker run --rm -v "$PWD":/usr/src/app prefixcli
    ls -l ./bin/prefixcli

## Testing

Manual testing for now:

    ./scripts/generate-test-output.sh | ./bin/prefixcli
    ./scripts/generate-test-output.sh | ./bin/prefixcli 'hello world'
    ./scripts/generate-test-output.sh | ./bin/prefixcli --sep=''
    ./scripts/generate-test-output.sh | ./bin/prefixcli --sep=' : '
    ./scripts/generate-test-output.sh | ./bin/prefixcli --eval 'HI=hi; echo $HI'
    ./scripts/generate-test-output.sh | pv --rate-limit=3 --quiet | ./bin/prefixcli

## Alternatives

 * ` | sed "s/^/$PREFIX /"`
 * ` | awk -v prefix="$PREFIX" '{ print prefix $0 }'`
 * ` | ruby -e 'prefix="PREFIX ";print prefix; while (s=gets(4)); print s.gsub(/[\r\n]/,"\\0#{prefix}"); end'`
    * `gets()` interferes with being able to pass the prefix in as an argument
