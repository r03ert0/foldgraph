#!/usr/bin/env bash

# spherical_all
# Roberto Toro, April 2019

RAW="../data/raw"
DEST="../data/derived/spherical"

# external commands
mp=../bin/meshparam/meshparam

cat ../data/subjects.txt| while read -r s; do
    echo "s: $s"
    mesh=${s#*/}
    mesh=${mesh%.ply}
    sub=${s%/*}

    mkdir -p "$DEST/$sub";

    echo "Make spherical meshes"
    $mp -i $RAW/$s -o $DEST/$sub/${mesh}_spherical.ply
done
