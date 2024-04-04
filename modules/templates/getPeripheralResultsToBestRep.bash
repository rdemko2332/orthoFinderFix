#!/usr/bin/env bash

set -euo pipefail

getPeripheralResultsToBestRep.pl --similarity $similarityResults \
				 --group $groupAssignments \
				 --bestReps bestReps.txt
