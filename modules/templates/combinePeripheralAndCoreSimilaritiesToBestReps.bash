#!/usr/bin/env bash

set -euo pipefail

mkdir final

# Need to do the core group results first. There may be core groups that contain not peripherals, but there will be no peripheral groups that do not contain any core proteins (those are the residuals)
cp $coreGroupSimilarities/*bestRep.tsv final/

# add in the peripherals (base name will be the same)
for f in *bestRep.tsv;
do
    cat \$f >> final/\$f
done


