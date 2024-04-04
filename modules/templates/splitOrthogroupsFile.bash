#!/usr/bin/env bash

set -euo pipefail
mv Results*/Orthogroups/Orthogroups.txt ./Orthogroups
rm -rf Results*
split Orthogroups OG
