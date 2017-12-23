perplexity=300

t=/Applications/_Sci/bh_tsne/bhtsne.py
ls -1d */*_curves.txt|while read f;do
    echo $f
    g=${f%.txt};
    awk '{if(NR==1){print $1,0,0}}' $f >${g}_tsne${perplexity}.txt
    awk '{if(NR==1){n=$1};if(NR>1&&NR<=1+n){printf "%f\t%f\t%f\n",$1,$2,$3}}' $f | $t -d 2 -p $perplexity >> ${g}_tsne${perplexity}.txt
done