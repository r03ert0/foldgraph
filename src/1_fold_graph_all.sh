#!/usr/bin/env bash

RAW="../data/raw"
DEST="../data/derived/skeleton"

# external command
f="./fold_graph-v4.sh"

cat ../data/subjects.txt| while read s; do
    echo s: $s
    mesh=${s#*/}
    sub=${s%/*}

    mkdir -p "$DEST/$sub";
    args="-i $RAW/$s -o $DEST/$sub"

    holes="$RAW/$sub/${mesh%.ply}_holesSurf.ply"
    echo "Looking for $holes"
    if [ -f $holes ]; then
        echo "Using precomputed mesh without sulci"
        args="${args} -p $holes"
    fi

    config="$RAW/$sub/config.txt"
    echo "Looking for $config"
    if [ -f $config ]; then
        echo "Using configuration file"
        x=$(sed 's/^/--/' $config)
        args="$args $x"
    fi

    $f $args
done