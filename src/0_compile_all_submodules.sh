#!/usr/bin/env bash

BASE_DIR="$PWD/../"

echo "Compile bhtsne"
if [ ! -f "$BASE_DIR/bin/bhtsne/bh_tsne" ]; then
    cd "$BASE_DIR/bin/bhtsne"
    g++ sptree.cpp tsne.cpp tsne_main.cpp -o bh_tsne -O2
fi

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

# echo "Compile libigl python bindings"
# if [ ! -d "$BASE_DIR/bin/libigl/build" ]; then
#    export PYTHON_LIBRARIES="/usr/local/Cellar/python/3.7.3/Frameworks/Python.framework/Versions/3.7/lib/libpython3.7m.dylib"
#    export PYTHON_INCLUDE_DIR="/usr/local/Cellar/python/3.7.3/Frameworks/Python.framework/Versions/3.7/include/python3.7m"
#    cd "$BASE_DIR/bin/libigl"
#    mkdir build
#    cd build
#    cmake ..
#    make
# fi

cd "$BASE_DIR/src"