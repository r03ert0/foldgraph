#!/usr/bin/env bash

# flatten_all
# Roberto Toro, May 2019

RAW="../data/raw"
SKEL="../data/derived/skeleton"
DEST="../data/derived/flat"

# external commands
sf="node spherical_graph.js"

cat ../data/douroucouli.txt| while read -r s; do
    echo "s: $s"
    mesh=${s#*/}
    mesh=${mesh%.ply}
    sub=${s%/*}

    mkdir -p "$DEST/$sub";

    args="$SKEL/$sub/${mesh}_skel_curves.txt $DEST/$sub/${mesh}"

    sconfig="$RAW/$sub/sphericalgraph-config.txt"
    echo "Looking for $sconfig"
    if [ -f "$sconfig" ]; then
        echo "Using configuration file"
        x=$(sed 's/^/--/' "$sconfig")
        args="$args $x"
    fi

    echo "Make flat graphs"
    echo $sf $args
    $sf $args
done
