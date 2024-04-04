#!/usr/bin/env bash

set -euo pipefail

sort -k 2 $groups > sortedGroups.txt

splitPeripheralProteomeByGroup.pl --groups sortedGroups.txt --proteome $proteome
