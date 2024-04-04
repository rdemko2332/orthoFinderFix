#!/usr/bin/env bash

set -euo pipefail

# unpack the tarball;  need to know the directory name which is unpacked
tar -xvzf $inputDir >tarOut
tarDir=`cat tarOut | head -1 | cut -f1`

touch output.fasta

for f in \$tarDir/*.fasta; do cat \$f >> output.fasta; done

mv \$tarDir fastas
