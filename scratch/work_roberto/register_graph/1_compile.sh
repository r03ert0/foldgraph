export LIBIGL_DIR="../../bin/libigl"
mkdir -p build
cd build
cmake .. -GXcode
make
cd ..
