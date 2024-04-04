#!/usr/bin/env bash

set -euo pipefail

makeResidualAndPeripheralFastas.pl --groups $groups \
				   --seqFile $seqFile \
				   --residuals residuals.fasta \
				   --peripherals peripherals.fasta
