#!/usr/bin/env bash

set -euo pipefail

for f in *.fasta; do
    echo \$f
    diamond makedb --in $bestRepFastas/\$f --db \$f

    diamond blastp \
      -d \$f.dmnd \
      -q \$f \
      -o \$f.bestRep.tsv \
      -f 6 $outputList \
      --ultra-sensitive \
      -e 1 \
      --min-score 0 \
      --unal 1

    sort -k 2 \$f.bestRep.tsv > diamondSimilarity.tmp
    mv diamondSimilarity.tmp \$f.bestRep.tsv;
done

# Rename all *fasta.bestRep.tsv to *.bestRep.tsv
for file in *.fasta.bestRep.tsv; do
    mv -- "\$file" "\${file%.fasta.bestRep.tsv}_bestRep.tsv"
done
