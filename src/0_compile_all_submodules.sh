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

echo "Download and compile graphite"
if [ ! -f "$BASE_DIR/bin/graphite3_1.7.3/" ]; then
    cd "$BASE_DIR/src"
    wget https://gforge.inria.fr/frs/download.php/file/38234/graphite3_1.7.3.zip
    mv graphite3_1.7.3.zip ../bin/
    cd ../bin/ || exit
    unzip graphite3_1.7.3.zip
    rm graphite3_1.7.3.zip
    cd graphite3_1.7.3 || exit

    # patch cmake options to generate binaries
    patch GraphiteThree/geogram/CMakeOptions.txt <<EOF
15c15
< set(GEOGRAM_LIB_ONLY ON)
---
> #set(GEOGRAM_LIB_ONLY ON)
EOF

    bash make_it.sh
    cd "$BASE_DIR/src"
fi
