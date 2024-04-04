#!/usr/bin/env bash

set -euo pipefail

for f in *.fasta; do mafft --auto --anysymbol \$f | fasttree -mlnni 4 > \$f.tree; done


