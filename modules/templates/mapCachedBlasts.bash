#!/usr/bin/env bash

set -euo pipefail

speciesMappingPath=$speciesMapping;
sequenceMappingPath=$sequenceMapping;

speciesMappingBase=\${speciesMappingPath##*/}
sequenceMappingBase=\${sequenceMappingPath##*/}

mkdir mappedCacheDir

mapCachedBlasts.pl --outdated $outdatedOrganisms \
    --cachedSpeciesMapping $previousDiamondCacheDirectory/\$speciesMappingBase \
    --cachedSequenceMapping $previousDiamondCacheDirectory/\$sequenceMappingBase \
    --newSpeciesMapping $speciesMapping \
    --newSequenceMapping $sequenceMapping \
    --diamondCacheDir $previousDiamondCacheDirectory \
    --outputDir mappedCacheDir
