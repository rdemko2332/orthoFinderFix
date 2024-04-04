#!/usr/bin/env bash

set -euo pipefail
diamond makedb --in $newdbfasta --db newdb
