#!/usr/bin/env bash

BASE_DIR="$PWD/../"

echo "Compile marching_cubes"
cd "$BASE_DIR/bin/marching_cubes"
if [ ! -f "marching_cubes" ]; then
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