#!/usr/bin/env bash

set -euo pipefail

ln -s $fastas/* ./

orthofinder -f . -op

#TODO:  what happens if there is more than one directory returned by this glob??
ln -s OrthoFinder/**/WorkingDirectory .

cp WorkingDirectory/SpeciesIDs.txt .
cp WorkingDirectory/SequenceIDs.txt .
