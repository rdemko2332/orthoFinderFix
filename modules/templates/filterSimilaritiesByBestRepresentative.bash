#!/usr/bin/env bash

set -euo pipefail

# NOTE:  The working directory needs to contain all of the similiarity files per group. named like "{group}.sim"

filterSimilaritiesByBestRepresentative.pl \
    --bestReps $bestReps \
    --singletons $singletons \
    --missingGroups $missingGroups
