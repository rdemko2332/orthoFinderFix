#!/usr/bin/env bash

set -euo pipefail

reformatGroupsFile.pl --groupFile $groupsFile --buildVersion $buildVersion

cat $translatedSingletons >> reformattedGroups.txt

if [ "$coreOrResidual" = "residual" ]; then
    mv reformattedGroups.txt holdReformat.txt
    sed 's/^OG/OGR/g' holdReformat.txt > reformattedGroups.txt
fi

