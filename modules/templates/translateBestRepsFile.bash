#!/usr/bin/env bash

set -euo pipefail

if [ "$isResidual" = "residual" ]; then
    translateBestRepsFile.pl --bestReps $bestReps \
	                     --sequenceIds $sequenceMapping \
			     --outputFile bestReps.txt \
			     --isResidual
else
    translateBestRepsFile.pl --bestReps $bestReps \
			     --sequenceIds $sequenceMapping \
			     --outputFile bestReps.txt
fi
