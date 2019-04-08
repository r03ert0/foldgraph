#!/usr/bin/env bash

mp=../bin/meshparam/meshparam

cat ../data/subjects.txt| while read s; do
    echo s: $s;
    mesh=${s#*/}
    sub=${s%/*}
    mkdir -p ../data/derived/spherical/$sub;
    $mp -i ../data/raw/$s -o ../data/derived/spherical/$sub/spherical.ply
done
