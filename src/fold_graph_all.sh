f=". fold_graph-v3.sh"

cat ../data/subjects.txt| while read s; do
    echo s: $s;
    mesh=${s#*/}
    sub=${s%/*}
    mkdir -p ../data/derived/skeleton/$sub;
    $f ../data/raw/$s ../data/derived/skeleton/$sub
done