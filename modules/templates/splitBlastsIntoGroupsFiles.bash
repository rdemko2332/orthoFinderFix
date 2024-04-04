#!/usr/bin/env bash

set -euo pipefail

splitBlastsIntoGroupsFiles.pl --input_file $blastsByOrthogroup \
			      --output_file_suffix ".sim"

echo "Done"
