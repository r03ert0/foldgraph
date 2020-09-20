#!/usr/bin/env bash

# flatten_all
# Roberto Toro, May 2019

DEST="../data/derived"

# external commands
sf="node simplify_foldgraph.js"

cat ../data/subjects.txt| while read -r s; do
    echo "s: $s"
    mesh=${s#*/}
    mesh=${mesh%.ply}
    sub=${s%/*}

    echo "Make adjacency matrix for $sub"
    $sf "$DEST/$sub/${mesh}_skel_curves_flat.txt" "$DEST/$sub/${mesh}"
done
