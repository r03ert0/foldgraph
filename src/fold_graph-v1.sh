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
ml=/Applications/_Graph/meshlab-133.app/Contents/MacOS/meshlabserver
sk=/Library/WebServer/Documents/tsne-skeleton/skeleton/skeleton/simple_mcfskel_example
c2c=/Library/WebServer/Documents/tsne-skeleton/skeleton/cgal2curves.py
c2g=/Library/WebServer/Documents/tsne-skeleton/skeleton/cgal2graph.py

echo "1. Light Laplace smooth, compute mean curvature, remove sulci, light Laplace smooth"
$mg -i $mesh_file -laplaceSmooth 0.5 10 -curv -addVal -0.1 -level 0 -removeVerts -laplaceSmooth 0.5 10 -o $holes_surf

diag=$($mg -i $holes_surf -size|cut -d' ' -f 2|awk -F, '{print sqrt($1**2+$2**2+$3**2)}')
diag5=$(echo $diag|awk '{print $1/5}');
precision=$(echo $diag|awk '{print $1*0.001}');
offset=$(echo $diag|awk '{print $1/5*2*0.002}');
echo diag $diag
echo precision $precision
echo offset $offset
precision=0.1
offset=0.3

echo "2. Extrude the mesh, Laplace smooth one more time"
cat>$scrpt<<EOF
<!DOCTYPE FilterScript>
<FilterScript>
 <filter name="Uniform Mesh Resampling">
  <Param type="RichAbsPerc" value="$precision" min="0" name="CellSize" max="$diag"/>
  <Param type="RichAbsPerc" value="$offset" min="-$diag5" name="Offset" max="0"/>
  <Param type="RichBool" value="false" name="mergeCloseVert"/>
  <Param type="RichBool" value="false" name="discretize"/>
  <Param type="RichBool" value="true" name="multisample"/>
  <Param type="RichBool" value="true" name="absDist"/>
 </filter>
</FilterScript>
EOF
$ml -i $holes_surf -o $holes_vol -s $scrpt
$mg -i $holes_vol -laplaceSmooth 0.5 40 -o $holes_vol

echo "3. Skeletonise"
$sk $holes_vol $skeleton $skeleton_correspondances

echo "4. Convert skeleton format, simplify the skeleton into a graph"
python $c2c $skeleton > $skeleton_curves
python $c2g $skeleton > $skeleton_graph
