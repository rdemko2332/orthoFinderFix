#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//---------------------------------------------------------------
// Including Workflows
//---------------------------------------------------------------

include { peripheralWorkflow } from './modules/peripheral.nf'
include { listToPairwiseComparisons; coreOrResidualWorkflow as coreWorkflow } from './modules/core.nf'

//---------------------------------------------------------------
// core
//---------------------------------------------------------------

workflow coreEntry {
    inputFile = Channel.fromPath(params.orthologgroups)
    sequenceMapping = Channel.fromPath(params.sequenceMapping)
    speciesMapping = Channel.fromPath(params.speciesMapping)
    diamond_ch = Channel.fromPath([params.diamondResults + '/*.txt'])
    workingDir_ch = Channel.fromPath([params.orthofinderWorkingDir])
    coreWorkflow(inputFile,sequenceMapping,speciesMapping,diamond_ch,workingDir_ch,"core")

}

//---------------------------------------------------------------
// peripheral
//---------------------------------------------------------------

workflow peripheralEntry {
  if(params.peripheralProteomes) {
    inputFile = Channel.fromPath(params.peripheralProteomes)
  }
  else {
    throw new Exception("Missing params.peripheralProteome")
  }

  peripheralWorkflow(inputFile)
   
}

//---------------------------------------------------------------
// DEFAULT - core
//---------------------------------------------------------------

workflow {
    //listToPairwiseComparisons(channel.of(1..10), 3).view();
    //listToPairwiseComparisons(channel.of(1..3).collect(), 2).view();
    coreEntry();
}
