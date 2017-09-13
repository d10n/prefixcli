# prefixcli

Prefix / prepend a string to CLI command output

## About

Sometimes in long-running output of a CLI command I want to prefix every line with a string.  
For example, timestamps on lines of a system update, timestamps on lines of a deploy, or the name of the current task being run in a list of tasks.

There is not an existing simple tool or one-liner I could find to do this already.  
The sed/awk/perl/ruby one-liners like ` | sed "s/^/$PREFIX /"` break down on progress bars made with carriage return.

prefixcli partially solves the progress bar problem because it properly handles `\r`.

The source has ugly comments while I figure nim stuff out.

## Caveats / TODO

 * Some progress bars get disabled because there is no pty.  
   Make a pty to handle those. (posix_openpt)  
   **Workaround**: Use `unbuffer` (part of the `expect` package) like in the example below
 * Lines on stderr are ignored (not prefixed) by default.  
   **Workaround**: If you want to prefix every line, redirect stderr to stdout with `2>&1` like in the example below

## Example output

    root@host:~
    # unbuffer pacman -Syy | prefixcli --eval 'date -u +%Y-%m-%dT%H:%M:%S%z'
    2017-09-13T02:32:18+0000 :: Synchronizing package databases...
    2017-09-13T02:32:18+0000  core                     124.4 KiB  2.43M/s 00:00 [#####] 100%
    2017-09-13T02:32:19+0000  extra                   1650.1 KiB  4.88M/s 00:00 [#####] 100%
    2017-09-13T02:32:20+0000  community                  4.0 MiB  6.88M/s 00:01 [#####] 100%

    user@host:~/temp
    $ ls
    bar/  baz/  foo/
    user@host:~/temp
    $ for dir in *; do pushd -q $dir; curl -# httpbin.org/uuid 2>&1 | tee uuid | prefixcli $dir; popd -q; done
    bar ######################################################################## 100.0%
    bar {
    bar   "uuid": "040c53d6-5076-45d1-95aa-419e3bb84a7f"
    bar }
    baz ######################################################################## 100.0%
    baz {
    baz   "uuid": "72d64574-21e8-4b98-81b8-86c4e67b6026"
    baz }
    foo ######################################################################## 100.0%
    foo {
    foo   "uuid": "9a88e474-bb35-4fe3-b0ab-5c430bebfc15"
    foo }

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
