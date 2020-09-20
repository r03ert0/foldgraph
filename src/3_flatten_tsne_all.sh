#!/usr/bin/env bash

# flatten_all
# Roberto Toro, May 2019

DEST="../data/derived"

# external commands
ff="node flatten_foldgraph_tsne.js"

cat ../data/subjects.txt| while read -r s; do
    echo "s: $s"
    mesh=${s#*/}
    mesh=${mesh%.ply}
    sub=${s%/*}

    echo "Make flat foldgraph for $sub"
    $ff "$DEST/$sub/${mesh}_skel_curves.txt" "$DEST/$sub/${mesh}"
done
