#!/usr/bin/env bash

RAW="../data/raw"
DEST="../data/derived/skeleton"

# external command
f="./fold_graph-v4.sh"

cat ../data/douroucouli.txt| while read -r s; do
    echo "s: $s"
    mesh=${s#*/}
    sub=${s%/*}

    mkdir -p "$DEST/$sub";
    args="-i $RAW/$s -o $DEST/$sub"

    holes_vol="$RAW/$sub/${mesh%.ply}_holesVol.ply"
    echo "Looking for $holes_vol volume"
    if [ -f "$holes_vol" ]; then
        echo "Using precomputed volumetric mesh without sulci"
        args="${args} -q $holes_vol"
    else
        holes_surf="$RAW/$sub/${mesh%.ply}_holesSurf.ply"
        echo "Looking for $holes_surf surface"
        if [ -f "$holes_surf" ]; then
            echo "Using precomputed surface mesh without sulci"
            args="${args} -p $holes_surf"
        fi
    fi

    config="$RAW/$sub/config.txt"
    echo "Looking for $config"
    if [ -f "$config" ]; then
        echo "Using configuration file"
        x=$(sed 's/^/--/' "$config")
        args="$args $x"
    fi

    $f $args
done