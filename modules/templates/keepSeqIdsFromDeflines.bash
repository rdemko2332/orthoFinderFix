#!/usr/bin/env bash

set -euo pipefail

mkdir filteredFastas

for f in *.fasta; do keepSeqIdsFromDeflines.pl \$f filteredFastas/\$f; done
