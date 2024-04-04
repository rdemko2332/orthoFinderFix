#!/usr/bin/env bash

set -euo pipefail

makeGroupsFile.pl --coreGroup $coreGroups \
		  --peripheralGroup $peripheralGroups \
		  --output GroupsFile.txt
