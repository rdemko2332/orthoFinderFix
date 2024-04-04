#!/usr/bin/env bash

set -euo pipefail

mkdir bestReps
splitCoreBestRepFasta.pl --bestReps $bestRepFasta --outputDir bestReps

