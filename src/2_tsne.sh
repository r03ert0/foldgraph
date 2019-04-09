#!/usr/bin/env bash
#!/usr/bin/env bash
# Roberto Toro, somewhere in 2016 I think...

SKEL="../data/derived/skeleton"
DEST="../data/derived/flat"

perplexity=300

# external command
t="python3 ../bin/bhtsne/bhtsne.py"

# flat all curves
ls -1d "$SKEL"/*/*_curves.txt|while read f;do
    g=$(echo "$f"|awk -F'/' '{print $(NF-1)}');
    echo $g
    mkdir -p "$DEST/$g"

    # get number of vertices, triangles (there's none), and edges
    dim=($(head -n 1 $f))

    # header
    head -n 1 $f > "$DEST/$g"/tsne${perplexity}.txt

    # vertices (flat)
    awk '{if(NR==1){n=$1};if(NR>1&&NR<=1+n){printf "%f\t%f\t%f\n",$1,$2,$3}}' $f \
    | $t -d 2 -p $perplexity >> "$DEST/$g"/tsne${perplexity}.txt

    # edges
    tail -n $((${dim[2]}+1)) $f >> "$DEST/$g"/tsne${perplexity}.txt
done