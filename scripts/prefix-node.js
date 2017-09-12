#!/usr/bin/env node
'use strict'

let prefix = process.argv[2] || '> '
let lastByteWasLf = true

process.stdin.on('data', chunk => {
    chunk = chunk
        .toString()
        .replace(/\r|\n(?!$)/g, match => match + prefix)
    if (lastByteWasLf) {
        process.stdout.write(prefix)
    }
    lastByteWasLf = chunk[chunk.length-1] === '\n'
    process.stdout.write(chunk)
})

process.stdin.setEncoding('utf8')
process.stdin.resume()
