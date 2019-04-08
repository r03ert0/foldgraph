#!/usr/bin/env bash

BASE_DIR="$PWD/../"

echo "Compile bhtsne"
if [ ! -f "$BASE_DIR/bin/bhtsne/bh_tsne" ]; then
    cd "$BASE_DIR/bin/bhtsne"
    g++ sptree.cpp tsne.cpp tsne_main.cpp -o bh_tsne -O2
fi

echo "Compile mesher"
cd "$BASE_DIR/bin/mesher"
if [ ! -f "mesh_a_3d_gray_image" ]; then
    cmake .
    make
fi

echo "Compile meshgeometry"
if [ ! -f "$BASE_DIR/bin/meshgeometry/meshgeometry_mac" ]; then
    cd "$BASE_DIR/bin/meshgeometry"
    source compile.sh
fi

echo "Compile meshparam"
if [ ! -f "$BASE_DIR/bin/meshparam/meshparam" ]; then
    cd "$BASE_DIR/bin/meshparam"
    source compile.sh
fi

echo "Compile skeleton"
cd "$BASE_DIR/bin/skeleton/skeleton"
if [ ! -f "skeleton" ]; then
    cmake .
    make
fi

echo "Compile volume"
if [ ! -f "$BASE_DIR/bin/volume/volume" ]; then
    cd "$BASE_DIR/bin/volume"
    source compile.sh
fi

cd "$BASE_DIR/src"