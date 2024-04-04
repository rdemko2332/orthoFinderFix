#!/usr/bin/env bash

set -euo pipefail

ln -s $orthofinderWorkingDir/* ./

orthofinder -a 5 -b .

#TODO:  what happens if there is more than one directory returned by this glob??
ln -s OrthoFinder/Results* ./Results
