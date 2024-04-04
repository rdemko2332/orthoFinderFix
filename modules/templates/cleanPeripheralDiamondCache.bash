#!/usr/bin/env bash

set -euo pipefail

cp -r $peripheralDiamondCache cleanedCache

removeOutdatedOrganisms.pl $outdatedOrganisms cleanedCache
