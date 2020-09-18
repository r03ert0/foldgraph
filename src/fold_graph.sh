#!/usr/bin/env bash

# fold_graph v5.1
# Roberto Toro, December 2019
# Katja Heuer, March 2020
# Usage:
#    bash fold_graph.sh -i mesh.ply -o destination_dir [-p mesh_with_holes.ply]
# Input: A mesh in ply format
# Output: A fold graph plus a series of intermediate results
# Optional: A mesh with sulci removed to use instead of computing one

# directory of the current script
MY_DIR="`dirname \"$0\"`"

# parse arguments
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -i|--input)
    src_mesh_file="$2"
    shift; shift
    ;;
    -o|--output-dir)
    dst_dir="$2"
    shift; shift
    ;;
    -p|--precomputed-holes-surf)
    precomputed_holes_surf="$2"
    shift; shift
    ;;
    -q|--precomputed-holes-vol)
    precomputed_holes_vol="$2"
    shift; shift
    ;;
    *)
    echo "Unknown argument [$key]"
    ;;
esac
done

# make sure that dst_dir is a directory name that ends with '/'
if [ "${dst_dir: -1:1}" != '/' ]; then dst_dir="$dst_dir/";fi

mesh=$(basename "${src_mesh_file%.ply}")
echo "mesh file: $src_mesh_file"
echo "mesh name: $mesh"
echo "destination: $dst_dir"

# file references
sulc_level0=${dst_dir}${mesh}_sulcLevel0.ply
sulc_map=${dst_dir}${mesh}_sulcMap.txt
holes_LUT=${dst_dir}${mesh}_holesLUT.txt
holes_surf=${dst_dir}${mesh}_holesSurf.ply
holes_vol=${dst_dir}${mesh}_holesVol
skeleton=${dst_dir}${mesh}_skel.cgal
skeleton_correspondances=${dst_dir}${mesh}_corresp.cgal
skeleton_curves=${dst_dir}${mesh}_skel_curves.txt
skeleton_graph=${dst_dir}${mesh}_skel_graph.txt

# binary references
mg="$MY_DIR/../bin/meshgeometry/meshgeometry_mac"
sk="$MY_DIR/../bin/skeleton/skeleton/skeleton"
c2c="$MY_DIR/../bin/skeleton/cgal2curves.py"
c2g="$MY_DIR/../bin/skeleton/cgal2graph.py"
# vl="$MY_DIR/../bin/graphite3_1.7.3/GraphiteThree/build/Darwin-clang-dynamic-Release/bin/vorpalite"

# processing

if [ "$precomputed_holes_vol" == "" ]; then
    if [ "$precomputed_holes_surf" == "" ]; then
        echo "1. Light Laplace smooth, compute mean curvature, remove sulci, light Laplace smooth"
        $mg \
            -i "$src_mesh_file" \
            -laplaceSmooth 0.5 10 \
            -curv \
            -addVal -0.1 \
            -level 0 \
            -o "$sulc_level0" \
            -odata "$sulc_map" \
            -removeVerts "$holes_LUT" \
            -laplaceSmooth 0.5 10 \
            -o "$holes_surf"

        #echo "2. Make spherical"
        #$mp -i "$sulc_level0" -o "$spherical"
    else
        echo "1. Using precomputed surface without sulci"
        cp "$precomputed_holes_surf" "$holes_surf"
    fi

    echo "2. Extrude the mesh"
    $mg -i "$holes_surf" -extrude -1 -o "$holes_vol.ply"
else
    echo "1. Using precomputed volumetric surface without sulci"
    cp "$precomputed_holes_vol" "$holes_vol.ply"
fi

echo "3. Skeletonise"
$mg -i "$holes_vol.ply" -o "$holes_vol.off"
$sk "$holes_vol.off" "$skeleton" "$skeleton_correspondances"
status=$?
if [ $status != 0 ]; then
    echo "ERROR"
    exit 1
fi

# echo "repair mesh"
# $vl profile=repair "$holes_vol.off" "$holes_vol.vl.off"
# echo "skeletonise"
# $sk "$holes_vol.vl.off" "$skeleton" "$skeleton_correspondances"

echo "4. Convert skeleton format, simplify the skeleton into a graph"
python "$c2c" "$skeleton" > "$skeleton_curves"
python "$c2g" "$skeleton" > "$skeleton_graph"
