#!/usr/bin/env nextflow
nextflow.enable.dsl=2


def collectDiamondSimilaritesPerGroup(diamondSimilaritiesPerGroup) {
    return diamondSimilaritiesPerGroup
        .flatten()
        .collectFile() { item -> [ item.getName(), item ] }
}



process uncompressFastas {
  container = 'veupathdb/orthofinder'

  input:
    path inputDir

  output:
    path 'fastas/*.fasta', emit: proteomes
    path 'output.fasta', emit: combinedProteomesFasta

  script:
    template 'uncompressFastas.bash'
}



process calculateGroupResults {
  container = 'veupathdb/orthofinder'

  //publishDir "$params.outputDir/groupStats", mode: "copy"

  input:
    path groupResultsToBestReps
    val evalueColumn
    val isResidual

  output:
    path 'groupStats*.txt'

  script:
    template 'calculateGroupResults.bash'
}


process bestRepsSelfDiamond {
  container = 'veupathdb/diamondsimilarity'

  input:
    path bestRepSubset
    path bestRepsFasta

  output:
    path 'bestReps.out'

  script:
    template 'bestRepsSelfDiamond.bash'
}
