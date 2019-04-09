#!/usr/bin/env bash

RAW="../data/raw"
DEST="../data/derived/skeleton"

# external command
f=". fold_graph-v3.sh"

cat ../data/subjects.txt| while read s; do
    echo s: $s;
    mesh=${s#*/}
    sub=${s%/*}
    mkdir -p "$DEST/$sub";
    $f "$RAW/$s" "$DEST/$sub"
done