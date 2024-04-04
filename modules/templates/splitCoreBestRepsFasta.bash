#!/usr/bin/env bash

set -euo pipefail

mkdir bestReps
splitCoreBestRepsFasta.pl --bestReps $bestRepsFasta --outputDir bestReps
