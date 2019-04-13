#!/usr/bin/env bash

# fold_graph
# Roberto Toro, April 2017
# Usage:
#    source fold_graph mesh.ply destination_dir [mesh_with_holes.ply]
# Input: A mesh in ply format
# Output: A fold graph plus a series of intermediate results
# Optional: A mesh with sulci removed to use instead of computing one

# defaults
level=1000
vox_dim=0.25

# parse arguments
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -i|--input)
    src_mesh_file="$2"
    shift; shift
    ;;
    -l|--isosurface-level)
    level="$2"
    shift; shift
    ;;
    -o|--output-dir)
    dst_dir="$2"
    shift; shift
    ;;
    -p|--precomputed-holes)
    precomputed_holes_surf="$2"
    shift; shift
    ;;
    -v|--vox-dim)
    vox_dim="$2"
    shift; shift
    ;;
    *)
    echo "Unknown argument [$key]"
    ;;
esac
done

# make sure that dst_dir is a directory name that ends with '/'
if [ ${dst_dir: -1:1} != '/' ]; then dst_dir="$dst_dir/";fi

mesh=$(basename ${src_mesh_file%.ply})
echo "mesh file: $src_mesh_file"
echo "mesh name: $mesh"
echo "destination: $dst_dir"

# file references
sulc_level0=${dst_dir}${mesh}_sulcLevel0.ply
sulc_map=${dst_dir}${mesh}_sulcMap.txt
holes_surf=${dst_dir}${mesh}_holesSurf.ply
holes_surf_vox=${dst_dir}${mesh}_holesSurfVox.ply
holes_vol=${dst_dir}${mesh}_holesVol
skeleton=${dst_dir}${mesh}_skel.cgal
skeleton_correspondances=${dst_dir}${mesh}_corresp.cgal
skeleton_curves=${dst_dir}${mesh}_skel_curves.txt
skeleton_graph=${dst_dir}${mesh}_skel_graph.txt
spherical=${dst_dir}${mesh}_spherical.ply

# binary references
mg=../bin/meshgeometry/meshgeometry_mac
v=../bin/volume/volume
mc=../bin/marching_cubes/marching_cubes
sk=../bin/skeleton/skeleton/skeleton
c2c=../bin/skeleton/cgal2curves.py
c2g=../bin/skeleton/cgal2graph.py
mp=../bin/meshparam/meshparam

# processing

if [ "$precomputed_holes_surf" == "" ]; then
    echo "1. Light Laplace smooth, compute mean curvature, remove sulci, light Laplace smooth"
    $mg -i $src_mesh_file -laplaceSmooth 0.5 10 -curv -addVal -0.1 -level 0 -o $sulc_level0 -odata $sulc_map -removeVerts -laplaceSmooth 0.5 10 -o $holes_surf

    echo "2. Make spherical"
    $mp -i $sulc_level0 -o $spherical
else
    echo "1. Using precomputed surface without sulci"
    cp $precomputed_holes_surf $holes_surf
fi

echo "3. Extrude the mesh"
read offx offy offz dimx dimy dimz <<<$($mg -i $holes_surf -size -printCentre\
|awk '/size/{split($2,s,",")}/centre/{split($2,c,",")}END{s[1]+=10;s[2]+=10;s[3]+=10;print c[1]-s[1]/2,c[2]-s[2]/2,c[3]-s[3]/2,int(s[1]+0.5),int(s[2]+0.5),int(s[3]+0.5)}')
dimx=$(echo $dimx/$vox_dim|bc)
dimy=$(echo $dimy/$vox_dim|bc)
dimz=$(echo $dimz/$vox_dim|bc)
echo volume dimensions: $dimx, $dimy, $dimz
echo voxel dimension: $vox_dim
echo offsets: $offx, $offy, $offz
echo "Convert mesh coordinates to voxel indices"

$mg \
    -i $holes_surf \
    -translate $(awk -v x=$offx -v y=$offy -v z=$offz 'BEGIN{printf"%g %g %g",-x,-y,-z}') \
    -scale $(awk -v d=$vox_dim 'BEGIN{e=1/d;printf"%g,%g,%g",e,e,e}') \
    -o $holes_surf_vox

$v \
    -new $dimx,$dimy,$dimz,$vox_dim,$vox_dim,$vox_dim,$offx,$offy,$offz \
    -strokeMesh $holes_surf_vox \
    -mult 10000 \
    -boxFilter 1 1 \
    -o ${dst_dir}tmp.bin \
    -o "${dst_dir}holes.nii.gz"

$mc ${dst_dir}tmp.bin ${dst_dir}tmp.hdr.txt $level $holes_vol.ply
$mg -i $holes_vol.ply -o $holes_vol.off
#rm ${dst_dir}tmp.nii.gz
rm ${dst_dir}tmp.bin
rm ${dst_dir}tmp.hdr.txt

echo "4. Skeletonise"
$sk $holes_vol.off $skeleton $skeleton_correspondances

echo "5. Convert skeleton format, simplify the skeleton into a graph"
python $c2c $skeleton > $skeleton_curves
python $c2g $skeleton > $skeleton_graph
