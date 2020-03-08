#!/usr/bin/env bash

# fold_graph v3
# Roberto Toro, April 2017
# Usage:
#    source fold_graph mesh.ply destination_dir [mesh_with_holes.ply]
# Input: A mesh in ply format
# Output: A fold graph plus a series of intermediate results
# Optional: A mesh with sulci removed to use instead of computing one

src_mesh_file="$1"
dst_dir="$2"
pre_holes_surf="$3"

# make sure that dst_dir is a directory name that ends with '/'
if [ ${dst_dir: -1:1} != '/' ]; then dst_dir="$dst_dir/";fi

mesh=$(basename ${src_mesh_file%.ply})
echo mesh file: $src_mesh_file
echo mesh name: $mesh
echo destination: $dst_dir

# file references
sulc_level0=${dst_dir}${mesh}_sulcLevel0.ply
sulc_map=${dst_dir}${mesh}_sulcMap.txt
holes_surf=${dst_dir}${mesh}_holesSurf.ply
holes_vol=${dst_dir}${mesh}_holesVol.off
skeleton=${dst_dir}${mesh}_skel.cgal
skeleton_correspondances=${dst_dir}${mesh}_corresp.cgal
skeleton_curves=${dst_dir}${mesh}_skel_curves.txt
skeleton_graph=${dst_dir}${mesh}_skel_graph.txt
spherical=${dst_dir}${mesh}_spherical.ply

# binary references
mg=../bin/meshgeometry/meshgeometry_mac
v=../bin/volume/volume
ms=../bin/mesher/mesh_a_3d_gray_image
sk=../bin/skeleton/skeleton/skeleton
c2c=../bin/skeleton/cgal2curves.py
c2g=../bin/skeleton/cgal2graph.py
mp=../bin/meshparam/meshparam

# processing

if [ "$pre_holes_surf" == "" ]; then
    echo "1. Light Laplace smooth, compute mean curvature, remove sulci, light Laplace smooth"
    $mg -i $src_mesh_file -laplaceSmooth 0.5 10 -curv -addVal -0.1 -level 0 -o $sulc_level0 -odata $sulc_map -removeVerts -laplaceSmooth 0.5 10 -o $holes_surf

    echo "2. Make spherical"
    $mp -i $sulc_level0 -o $spherical
else
    echo "1. Using precomputed surface without sulci"
    cp $pre_holes_surf $holes_surf
fi

echo "3. Extrude the mesh"
read offx offy offz dimx dimy dimz <<<$($mg -i $holes_surf -size -printCentre\
|awk '/size/{split($2,s,",")}/centre/{split($2,c,",")}END{s[1]+=10;s[2]+=10;s[3]+=10;print c[1]-s[1]/2,c[2]-s[2]/2,c[3]-s[3]/2,int(s[1]+0.5),int(s[2]+0.5),int(s[3]+0.5)}')
read pixdimx pixdimy pixdimz <<<$(echo 0.125 0.125 0.125)
dimx=$(echo $dimx/$pixdimx|bc)
dimy=$(echo $dimy/$pixdimy|bc)
dimz=$(echo $dimz/$pixdimz|bc)
echo volume dimensions: $dimx, $dimy, $dimz
echo pixel dimensions: $pixdimx, $pixdimy, $pixdimz
echo offsets: $offx, $offy, $offz
$v -new $dimx,$dimy,$dimz,$pixdimx,$pixdimy,$pixdimz,$offx,$offy,$offz -strokeMesh $src_mesh_file -not -connected 0,0,0,0 -o ${dst_dir}tmp.nii.gz
$v -new $dimx,$dimy,$dimz,$pixdimx,$pixdimy,$pixdimz,$offx,$offy,$offz -strokeMesh $holes_surf -dilate 5 -and ${dst_dir}tmp.nii.gz -mult 10000 -boxFilter 1 1 -o ${dst_dir}tmp.inr -o ${dst_dir}holes.nii.gz
$ms ${dst_dir}tmp.inr $holes_vol
rm ${dst_dir}tmp.nii.gz
rm ${dst_dir}tmp.inr

echo "4. Skeletonise"
$sk $holes_vol $skeleton $skeleton_correspondances

echo "5. Convert skeleton format, simplify the skeleton into a graph"
python $c2c $skeleton > $skeleton_curves
python $c2g $skeleton > $skeleton_graph
