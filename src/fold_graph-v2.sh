# fold_graph
# Roberto Toro, April 2017
# Usage:
#    source fold_graph mesh.ply
# Input: A mesh in ply format
# Output: A fold graph plus a series of intermediate results

mesh_file="$1"
mesh=${mesh_file%.ply}
echo $mesh $mesh_file
holes_surf=${mesh}_holesSurf.ply
holes_vol=${mesh}_holesVol.off
scrpt=${mesh}_script.mlx
skeleton=${mesh}_skel.cgal
skeleton_correspondances=${mesh}_corresp.cgal
skeleton_curves=${mesh}_skel_curves.txt
skeleton_graph=${mesh}_skel_graph.txt

mg=/Users/roberto/Applications/brainbits/m.meshgeometry/meshgeometry_mac
v=/Users/roberto/Applications/brainbits/v.volume/volume
ms=/Users/roberto/Applications/brainbits/v.mesher/mesh_a_3d_gray_image
sk=/Library/WebServer/Documents/tsne-skeleton/skeleton/skeleton/simple_mcfskel_example
c2c=/Library/WebServer/Documents/tsne-skeleton/skeleton/cgal2curves.py
c2g=/Library/WebServer/Documents/tsne-skeleton/skeleton/cgal2graph.py

echo "1. Light Laplace smooth, compute mean curvature, remove sulci, light Laplace smooth"
$mg -i $mesh_file -laplaceSmooth 0.5 10 -curv -addVal -0.1 -level 0 -removeVerts -laplaceSmooth 0.5 10 -o $holes_surf

echo "2. Extrude the mesh, Laplace smooth one more time"
read mx my mz sx sy sz <<<$($mg -i $holes_surf -size -printCentre|awk '/size/{split($2,s,",")}/centre/{split($2,c,",")}END{s[1]+=2;s[2]+=2;s[3]+=2;print c[1]-s[1]/2,c[2]-s[2]/2,c[3]-s[3]/2,s[1],s[2],s[3]}')
read dx dy dz <<<$(echo 0.25 0.25 0.25)

$v -new $sx,$sy,$sz,$dx,$dy,$dz,$mx,$my,$mz -strokeMesh $orig -not -connected 0,0,0,0 -o $tmp.nii.gz
$v -new $sx,$sy,$sz,$dx,$dy,$dz,$mx,$my,$mz -strokeMesh $gyri -dilate 4 -and $tmp.nii.gz -mult 10000 -boxFilter 1 2 -o $tmp.inr
$ms $tmp.inr $holes_vol

echo "3. Skeletonise"
$sk $holes_vol $skeleton $skeleton_correspondances

echo "4. Convert skeleton format, simplify the skeleton into a graph"
python $c2c $skeleton > $skeleton_curves
python $c2g $skeleton > $skeleton_graph
