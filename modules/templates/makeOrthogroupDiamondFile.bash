#!/usr/bin/env bash

set -euo pipefail

SPECIES_0_ORTHOLOGS=${target}.orthologs

mkdir needed
for query in ${queries.join(' ')}; do
    SPECIES_1_ORTHOLOGS=\$query.orthologs
    DIAMOND_FILE=Blast${target}_\${query}.txt
    mv \$SPECIES_1_ORTHOLOGS needed
    mv \$DIAMOND_FILE needed
done

if [ -f "./\$SPECIES_0_ORTHOLOGS" ]; then
  mv \$SPECIES_0_ORTHOLOGS needed
fi

rm Blast*
if [ -f "./*.orthologs" ]; then
  rm *.orthologs
fi
mv needed/* .

for query in ${queries.join(' ')}; do
    SPECIES_1_ORTHOLOGS=\$query.orthologs

    DIAMOND_FILE=Blast${target}_\${query}.txt
    OUTPUT_FILE=OrthologGroup_Blast\${query}_${target}.txt

    makeOrthologGroupDiamondFiles.pl --species0 \$SPECIES_0_ORTHOLOGS \
				     --species1 \$SPECIES_1_ORTHOLOGS \
				     --diamondFile \$DIAMOND_FILE \
				     --outputFile \$OUTPUT_FILE;
    sort \$OUTPUT_FILE >\$OUTPUT_FILE.sorted
    rm \$OUTPUT_FILE
    rm \$DIAMOND_FILE
done;

rm -rf needed

echo "Done"
