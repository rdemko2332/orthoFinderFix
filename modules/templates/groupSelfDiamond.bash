#!/usr/bin/env bash

set -euo pipefail

if [ -s ${groupFasta} ]; then
  diamond makedb --in $groupFasta --db newdb
  diamond blastp \
	-d newdb.dmnd \
	-q $groupFasta \
	-o ${groupFasta}.out \
	-f 6 qseqid qlen sseqid slen qstart qend sstart send evalue bitscore length nident pident positive qframe qstrand gaps qcovhsp scovhsp qseq \
        --comp-based-stats 0 \
	--no-self-hits \
	--very-sensitive \
	$blastArgs
fi 

if [ -f "/cache/previousResults/${groupFasta}.out" ]; then
  cat /cache/previousResults/${groupFasta}.out >> ${groupFasta}.out
fi

if [ -f "/cache/previousFastas/${groupFasta}" ]; then
  cat /cache/previousFastas/${groupFasta} >> $groupFasta
fi
