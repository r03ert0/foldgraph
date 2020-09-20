#!/usr/bin/env bash

# spherical_all
# Roberto Toro, April 2019

DERIVED="../data/derived"

# external commands
mp=../bin/meshparam/meshparam

cat ../data/subjects.txt| while read -r s; do
    echo "s: $s"
    mesh=${s#*/}
    mesh=${mesh%.ply}
    sub=${s%/*}

    echo "Make spherical meshes"
    $mp -i "$DERIVED/$sub/${mesh}_sulcLevel0.ply" -o "$DERIVED/$sub/${mesh}_spherical.ply"
done
