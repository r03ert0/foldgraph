f=". fold_graph-v2.sh"

cat ../data/raw-data/subjects.txt| while read s; do
    echo $s;
    base=${s%/*}
    sub=${s#*/}
    mkdir -p $base;
    if [ ! -f $s ]; then
        ln -s $dir/$s $s
    fi
    $f $s
done