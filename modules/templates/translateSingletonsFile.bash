#!/usr/bin/env bash

set -euo pipefail

translateSingletonsFile.pl --singletons $singletonsFile \
			   --sequenceMapping $sequenceMapping 

sort -k 1 translated.out > translatedSingletons.dat
