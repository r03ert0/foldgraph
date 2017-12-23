dir=/Users/roberto/Documents/2016_06BrainCatalogue\;Osoianu/BrainCatalogueWorkflow/meshes_centered

f="source /Users/roberto/Desktop/fold_graph/fold_graph.sh"

cat subjects.txt| while read s; do
    echo $s;
    base=${s%/*}
    sub=${s#*/}
    mkdir -p $base;
    if [ ! -f $s ]; then
        ln -s $dir/$s $s
    fi
    $f $s
done