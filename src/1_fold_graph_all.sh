#!/usr/bin/env bash

RAW="../data/raw"
DEST="../data/derived"

# external command
f="./fold_graph.sh" # fold_graph v5.1

cat "../data/subjects.txt"| while read -r s; do
    echo -e "\ns: $s"
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

    fconfig="$RAW/$sub/foldgraph-config.txt"
    echo "Looking for $fconfig"
    if [ -f "$fconfig" ]; then
        echo "Using configuration file"
        x=$(sed 's/^/--/' "$fconfig")
        args="$args $x"
    fi

    $f $args
done