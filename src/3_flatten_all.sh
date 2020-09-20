#!/usr/bin/env bash

# flatten_all
# Roberto Toro, May 2019

RAW="../data/raw"
DEST="../data/derived"

# external commands
ff="python flatten_foldgraph.py"

cat ../data/subjects.txt| while read -r s; do
    echo "s: $s"
    mesh=${s#*/}
    mesh=${mesh%.ply}
    sub=${s%/*}

    echo "Make flat foldgraph for $sub"
    $ff "$DEST/$sub/${mesh}"
done
