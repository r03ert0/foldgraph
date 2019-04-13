#!/usr/bin/env bash
#!/usr/bin/env bash
# Roberto Toro, somewhere in 2016 I think...

SKEL="../data/derived/skeleton"
DEST="../data/derived/flat"
max_perplexity=300
target=curves

# external command
t="python3 ../bin/bhtsne/bhtsne.py"

# flat all curves
ls -1d "$SKEL"/*/*_${target}.txt|while read f;do
    g=$(echo "$f"|awk -F'/' '{print $(NF-1)}');
    echo $g

    # get number of vertices, triangles (there's none), and edges
    # adjust the perplexity
    dim=($(head -n 1 $f))
    perplexity=$(awk -v perp=$max_perplexity -v n=${dim[0]} 'BEGIN{if(perp>n/3)printf"%i",n/3;else print perp}')

    # make destination directory
    mkdir -p "$DEST/$g"
    sub="$DEST/$g"/tsne_${target}_${perplexity}.txt

    # header
    head -n 1 $f > $sub

    # vertices (flat)
    awk '{if(NR==1){n=$1};if(NR>1&&NR<=1+n){printf "%f\t%f\t%f\n",$1,$2,$3}}' $f \
    | $t --use_pca -d 2 -p $perplexity >> $sub
    success=$(echo $?)

    # edges
    tail -n $((${dim[2]}+1)) $f >> $sub
    mv $sub "$DEST/$g"/tsne_${target}_${perplexity}.txt
done