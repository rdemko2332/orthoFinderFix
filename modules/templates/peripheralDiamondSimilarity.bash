#!/usr/bin/env bash

set -euo pipefail

BLAST_FILE=$peripheralDiamondCache/${fasta}.out

if [ -f "\$BLAST_FILE" ]; then
        echo "Taking from Cache for \$BLAST_FILE"
        ln -s \$BLAST_FILE .
else
    diamond blastp \
      -d $database \
      -q $fasta \
      -o ${fasta}.out \
      -f 6 $outputList \
      -e 0.00001 \
      --very-sensitive \
      --comp-based-stats 0

    sort -k 2 ${fasta}.out > diamondSimilarity.tmp
    mv diamondSimilarity.tmp ${fasta}.out
fi


