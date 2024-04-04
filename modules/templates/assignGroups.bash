#!/usr/bin/env bash

set -euo pipefail

assignGroupsForPeripherals.pl --result $diamondInput \
			      --output groups.txt \
			      --groupFile $groupFile

