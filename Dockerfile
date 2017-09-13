FROM nimlang/nim:alpine

RUN apk add --update pcre-dev

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

CMD if [ ! -r prefixcli.nimble ]; then echo 'Error running. Ensure the directory is shared.'; echo 'docker run --rm -v "$PWD":/usr/src/app prefixcli'; exit 1; fi; mkdir -p bin && nimble install --depsOnly -y && nim --passL:-static --passL:'/usr/lib/libpcre.a' --define:usePcreHeader c --out:bin/prefixcli --opt:size -d:release src/prefixcli.nim && strip -s bin/prefixcli

