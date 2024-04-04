#!/usr/bin/env bash

set -euo pipefail

 sort -k 1 ${bestRepsBlast} > sorted.tmp

formatSimilarOrthogroups.pl --input sorted.tmp --output similarOrthogroups.txt
