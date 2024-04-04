#!/usr/bin/env bash

set -euo pipefail

IS_RESIDUAL_PARAM=""
OUTPUT="groupStats.txt"

if [ "$isResidual" = true ]; then
    IS_RESIDUAL_PARAM="--isResidual"
    OUTPUT="groupStats_residual.txt"
fi

tail -n +1 *.tsv > combined.tsv

calculateGroupResults.pl --outputFile "\$OUTPUT" --bestRepResults combined.tsv --evalueColumn $evalueColumn \$IS_RESIDUAL_PARAM
