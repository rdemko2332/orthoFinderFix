#!/usr/bin/env bash

set -euo pipefail

mkdir cleanedFastas

# unpack the tarball;  need to know the directory name which is unpacked
tar -xvzf $proteomes >tarOut
tarDir=`cat tarOut | head -1`

for f in \$tarDir/*.fasta;
do
    separateProteinsWithAllAmbiguousAminoAcids.pl --input \$f --ambiguous "\${f}.ambiguous" --unambiguous "\${f}.unambiguous";
    cat \${f}.unambiguous \${f}.ambiguous >cleanedFastas/\${f##*/}
    rm \${f}.unambiguous \${f}.ambiguous
done
