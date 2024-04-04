#!/usr/bin/env bash

set -euo pipefail

touch fullProteome.fasta
cat $coreProteome >> fullProteome.fasta
echo "" >> fullProteome.fasta
cat $peripheralProteome >> fullProteome.fasta
