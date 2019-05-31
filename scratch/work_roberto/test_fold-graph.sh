#!/usr/bin/env bash

mg="/Users/roberto/Applications/brainbits/m.meshgeometry/meshgeometry_mac" # mesh geometry
td="/Applications/_Graph/vcglib/apps/tridecimator/tridecimator" # mesh triangle decimator
fo="source /Users/roberto/Desktop/annex/fold-graph/fold_graph.sh" # fold graph
base="/Users/roberto/Documents/2016_06BrainCatalogue-Osoianu/BrainCatalogueWorkflow/meshes_centered" # base data directory
out="/Users/roberto/Desktop/test_fold-graph"
# db=(baboon capuchin ce_macaque chimpanzee douroucouli galago gorilla mangabey orangutan rhesus_macaque roberto slow_loris) # list of subjects
db=(baboon) # test subject

# 1. vertex density
for s in ${db[@]}; do
    echo $s
    
    mkdir -p $out/$s

    # get surface area and number of vertices
    read area ntris <<<$($mg -i $base/$s/both.ply -area -tris|awk '/area/{a=$2}/tris/{t=$2}END{print a,t}')

    # for a range of target number of triangles per mm2
    for d in 0.5 0.75 1; do
        
        # generate meshes
        target=$(awk 'BEGIN{printf"%i",(0.5+'$d'*'$area')}')
        if (( $target > $ntris )); then
            it=$(awk 'function ceil(v){return(v==int(v))?v:int(v)+1}BEGIN{printf"%i",ceil(log('$target'/'$ntris')/log(3))}')
            echo "subdivide $it times so that $ntris > $target"
            ntris1=$($mg -i $base/$s/both.ply $(for ((i=0;i<$it;i++));do echo -n "-subdivide ";done) -tris -o $out/$s/$s.$target.ply|awk '/tris/{print $2}')
            if (( $target < $ntris1 )); then
                echo "decimate so that $ntris1 == $target"
                $td $out/$s/$s.$target.ply $out/$s/$s.level$d.ply $target
                rm $out/$s/$s.$target.ply
            fi
        elif (( $target < $ntris )); then
            echo "decimate so that $ntris == $target"
            $td $base/$s/both.ply $out/$s/$s.level$d.ply $target
        else
            echo "the mesh has the right number of triangles"
            cp $base/$s/both.ply $out/$s/$s.level$d.ply
        fi
    
        # run fold-graph
        $fo $out/$s/$s.level$d.ply
    done
done

# 2. smoothing scales

# 3. effect of changes in mean curvature level used to remove sulci

# 4. remove gyri instead

# 5. dual graph: make gyri the nodes

# example call to gedevo:
# ./gedevo --edgelist /Users/roberto/Desktop/graph_u.sif --edgelist /Users/roberto/Desktop/graph_v.sif -u --save test.txt --maxsame 50