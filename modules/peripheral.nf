#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { calculateGroupResults; uncompressFastas; uncompressFastas as uncompressPeripheralFastas; collectDiamondSimilaritesPerGroup} from './shared.nf'
include { coreOrResidualWorkflow as residualWorkflow  } from './core.nf'

/**
 * Splits peripheral proteome into one fasta per organism. Place these into a singular directory and compress.
 * This is the input for orthofinder.
 *
 * @param inputFasta:  The fasta file containing all of the peripheral sequences
 * @return fastaDir A compressed directory of proteomes fastas
*/
process createCompressedFastaDir {
  container = 'veupathdb/orthofinder'

  input:
    path inputFasta

  output:
    path 'fastas.tar.gz', emit: fastaDir
    stdout emit: complete

  script:
    template 'createCompressedFastaDir.bash'
}

/**
 * Creates a diamond database from the core best representatives
 *
 * @param newdbfasta: An input fasta containing the core best representative sequences  
 * @return newdb.dmnd A diamond database to be used in diamond jobs
*/
process createDatabase {
  container = 'veupathdb/orthofinder'

  input:
    path newdbfasta

  output:
    path 'newdb.dmnd'

  script:
    template 'createDatabase.bash'
}

/**
 * Blast a peripheral proteome against the core best representative diamond database
 *
 * @param fasta: A peripheral organism proteome
 * @param database: The diamond database of core best representatives
 * @param peripheralDiamondCache: A directory of diamond output files, named by organism, from the last peripheral run
 * @param outputList: A string of output fields to tell diamond what outout we want to retriece in a tsv format
 * @return similarities The diamond output file containing pairwise similarities
 * @return fasta The peripheral organism proteome
*/
process peripheralDiamond {
  container = 'veupathdb/diamondsimilarity'

  publishDir "$params.outputDir/newPeripheralDiamondCache", mode: "copy", pattern: "*.out"

  input:
    path fasta
    path database
    path peripheralDiamondCache
    val outputList

  output:
    path '*.out', emit: similarities
    path fasta, emit: fasta


  script:
    template 'peripheralDiamondSimilarity.bash'
}

/**
 * Assign groups to sequences based off the lowest e-value of each sequence when blasted against all of the core best representatives
 *
 * @param diamondInput: The diamond output file from the peripheralDiamond process
 * @param param: The peripheral organism proteome
 * @return sortedGroups A tsv file. Each line contains the sequence ID and the group it has been assigned to
 * @return diamondInput The diamond output file from the peripheralDiamond process
 * @return fasta The peripheral organism proteome
*/
process assignGroups {
  container = 'veupathdb/orthofinder'

  input:
    path diamondInput
    path fasta
    path groupFile
        
  output:
    path 'groups.txt', emit: groups
    path diamondInput, emit: similarities
    path fasta, emit: fasta

  script:
    template 'assignGroups.bash'
}

/**
 * Filter similarities file to only contain blast results between a peripheral sequence and the core best representative of the group they were assigned
 *
 * @param similarityResults: The diamond similarity results output file
 * @param groupAssignments: The file containing the peripheral sequences and the groups they were assigned to
 * @return groupSimilarities Multiple tsv output files. One per group
 * Each containing blast results involving sequences assigned to the group
 * (will all have the same sseqid in the second column of the file, as blast results all involved the core best representative for that group)
*/
process getPeripheralResultsToBestRep {
  container = 'veupathdb/orthofinder'
  
  input:
    path similarityResults
    path groupAssignments
    path coreBestReps
        
  output:
    path '*.tsv', emit: groupSimilarities, optional: true

  script:
    template 'getPeripheralResultsToBestRep.bash'
}

/**
 * Creates a peripheral (non-residual) and residual fasta file. If a sequence was assigned a group (had pairwise result to a core best representative that's e-value score was below our cutoff), it is a non-residual and is sent to the peripheral fasta. If the sequence was not assigned to a group, it is sent to the residual fasta file.
 *
 * @param groups: The file containing the peripheral sequences and the groups they were assigned to
 * @param param: The peripheral organism proteome
 * @return residualFasta A fasta file containing the residual sequences (sequences that have not been assigned to a group)
 * @return peripheralFasta A fasta file containing the peripheral (non-residual) sequences
*/
process makeResidualAndPeripheralFastas {
  container = 'veupathdb/orthofinder'

  publishDir params.outputDir, mode: "copy"
  
  input:
    path groups
    path seqFile
        
  output:
    path 'residuals.fasta', emit: residualFasta
    path 'peripherals.fasta', emit: peripheralFasta

  script:
    template 'makeResidualAndPeripheralFastas.bash'
}

/**
 * Remove the cache pairwise blast results from the last peripheral run for all peripheral organisms that have changed proteomes
 *
 * @param outdatedOrganisms: A text file, with the organism abbreviation of a peripheral organism that has an updated proteome since the last peripheral run, one per line
 * @param peripheralDiamondCache: A directory containing the diamond results from the last peripheral workflow run. One file per organism to the core best representative diamond database
 * @return cleanedCache A new directory that contains diamond results for peripheral organism that have not changed. We can retrieve their results from the cache as they have not changed
*/
process cleanPeripheralDiamondCache {
  container = 'veupathdb/orthofinder'

  input:
    path outdatedOrganisms
    path peripheralDiamondCache 

  output:
    path 'cleanedCache'

  script:
    template 'cleanPeripheralDiamondCache.bash'
}

/**
 * Combine the core and peripheral proteome
 *
 * @param coreProteome: A fasta file containing all of the core sequences
 * @param peripheralProteome: A fasta file containing all of the peripheral sequences
 * @return fullProteome The combined proteome fasta
*/
process combineProteomes {
  container = 'veupathdb/orthofinder'

  input:
    path coreProteome
    path peripheralProteome

  output:
    path 'fullProteome.fasta'

  script:
    template 'combineProteomes.bash'
}

/**
 * Adds the peripheral sequence ids to the groups file generated by the core nextflow workflow
 *
 * @param coreGroups: The groups file from the core nextflow workflow
 * @param peripheralGroups: The groups file containing a peripheral sequence ID and the group it has been assigned to  
 * @return GroupsFile The full groups file containing core and peripheral sequences
*/
process makeGroupsFile {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path coreGroups
    path peripheralGroups

  output:
    path 'GroupsFile.txt'

  script:
    template 'makeGroupsFile.bash'
}

/**
 * Split the combined core and peripheral proteome by group
 *
 * @param proteome: The full combined core and peripheral proteome
 * @param groups: The full groups file
 * @param outdated: The outdated organism file  
 * @return fasta A fasta file per group
*/
process splitProteomeByGroup {
  container = 'veupathdb/orthofinder'

  input:
    path proteome
    path groups
    path outdated

  output:
    path '*.fasta'

  script:
    template 'splitProteomeByGroup.bash'
}

process splitPeripheralProteomeByGroup {
  container = 'veupathdb/orthofinder'

  input:
    path proteome
    path groups

  output:
    path 'OG*.fasta', emit: peripheralGroupFastas

  script:
    template 'splitPeripheralProteomeByGroup.bash'
}

process splitCoreBestRepFasta {
  container = 'veupathdb/orthofinder'

  input:
    path bestRepFasta

  output:
    path 'bestReps', emit: bestRepsFastas

  script:
    template 'splitCoreBestRepFasta.bash'
}

process peripheralGroupsToBestRepDiamond {
  container = 'veupathdb/orthofinder'

  input:
    path groupFastas
    path bestRepFastas
    val outputList

  output:
    path '*.tsv', emit: groupSimilarities

  script:
    template 'peripheralGroupsToBestRepDiamond.bash'
}

/**
 * Keep only the sequence Ids in the deflines of the fasta files. Remove all other information. Needed for the createGeneTrees software.
 *
 * @param fastas: Group proteomes  
 * @return filteredFastas Group fasta files that have deflines only containing sequence ids
*/
process keepSeqIdsFromDeflines {
  container = 'veupathdb/orthofinder'

  input:
    path fastas

  output:
    path 'filteredFastas/*.fasta', optional: true

  script:
    template 'keepSeqIdsFromDeflines.bash'
}

/**
 * Create a gene tree per group
 *
 * @param fasta: A group fasta file from the keepSeqIdsFromDeflines process  
 * @return tree Output group tree file
*/
process createGeneTrees {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/geneTrees", mode: "copy"

  input:
    path fasta

  output:
    path '*.tree'

  script:
    template 'createGeneTrees.bash'
}

/**
 * Combines blast similarities. One file per core and peripheral.
 *  Core sequences between them and the best representative for the group to which they were assigned. Same for the peripherals.
 *  This will give us all of the needed similarity score to generate group statistics.
 *
 * @param peripheralGroupSimilarities: Pairwise blast results between peripheral sequences and the core best representative for the group to which they were assigned
 * @param coreGroupSimilarities: Pairwise blast results between core sequences and the core best representative for the group to which they were assigned
 * @return final Pairwise blast result files per group containing all results involving core and peripheral sequences to the best representative of they group to which they were assigned
*/
process combinePeripheralAndCoreSimilaritiesToBestReps {
  container = 'veupathdb/orthofinder'

  input:
    path peripheralGroupSimilarities
    path coreGroupSimilarities

  output:
    path 'final/*'

  script:
    template 'combinePeripheralAndCoreSimilaritiesToBestReps.bash'
}


workflow peripheralWorkflow { 
  take:
    peripheralDir

  main:

    // Uncompress input directory that contains a proteome fasta per organism. This is done for both the core and peripheral.
    uncompressAndMakePeripheralFastaResults = uncompressPeripheralFastas(peripheralDir)
    uncompressAndMakeCoreFastaResults = uncompressFastas(params.coreProteomes)

    // Create a diamond database from a fasta file of the core best representatives
    database = createDatabase(uncompressAndMakeCoreFastaResults.combinedProteomesFasta)

    // Remove cached diamond results for organisms proteomes that have changed
    cleanPeripheralDiamondCacheResults = cleanPeripheralDiamondCache(params.outdatedOrganisms,
                                                                     params.peripheralDiamondCache)

    // Run Diamond (forks so we get one process per organism; )
    similarities = peripheralDiamond(uncompressAndMakePeripheralFastaResults.proteomes.flatten(),
                                     database,
				     cleanPeripheralDiamondCacheResults,
				     params.orthoFinderDiamondOutputFields)

    // Assigning Groups
    groupsAndSimilarities = assignGroups(similarities.similarities,
                                         similarities.fasta,
					 params.coreGroupsFile)

    // split out residual and peripheral per organism and then collect into residuals and peripherals fasta
    residualAndPeripheralFastas = makeResidualAndPeripheralFastas(groupsAndSimilarities.groups,
                                                                  groupsAndSimilarities.fasta)

    residualFasta = residualAndPeripheralFastas.residualFasta.collectFile(name: 'residual.fasta');
    peripheralFasta = residualAndPeripheralFastas.peripheralFasta.collectFile(name: 'peripheral.fasta');

    // collect up the groups
    groupAssignments = groupsAndSimilarities.groups.collectFile(name: 'groups.txt')

    peripheralProteomesByGroup = splitPeripheralProteomeByGroup(peripheralFasta, groupAssignments)

    coreBestRepFastas = splitCoreBestRepFasta(params.coreBestRepsFasta)

    peripheralSimilaritiesToBestRep =  peripheralGroupsToBestRepDiamond(peripheralProteomesByGroup.peripheralGroupFastas.flatten().collate(100),
                                                                        coreBestRepFastas.bestRepsFastas.collect(),
				                                        params.orthoFinderDiamondOutputFields)
									.collect()

    // in one file PER GROUP, combine core + peripheral similarities
    allSimilaritiesToBestRep = combinePeripheralAndCoreSimilaritiesToBestReps(peripheralSimilaritiesToBestRep,
                                                                              params.coreSimilarityToBestReps);

    // for X number of groups (100?), calculate stats on evalue
    calculateGroupResults(allSimilaritiesToBestRep.flatten().collate(100),
                          10,
    			  false)
    			  .collectFile(name: "peripheral_stats.txt",
    			               storeDir: params.outputDir + "/groupStats" )

    // Creating Core + Peripheral Gene Trees

    // Combine core and peripheral proteomes into a singular file
    combinedProteome = combineProteomes(uncompressAndMakeCoreFastaResults.combinedProteomesFasta,
                                        peripheralFasta)

    // TODO: these 4 steps need work
       makeGroupsFileResults = makeGroupsFile(params.coreGroupsFile, groupAssignments)
       splitProteomesByGroupResults = splitProteomeByGroup(combinedProteome, makeGroupsFileResults.splitText( by: 100, file: true ), params.outdatedOrganisms)
       createGeneTrees(splitProteomesByGroupResults)

    // Residual Processing

    // Split residual proteome into one fasta per organism and compress. Needed input for orthofinder.
    compressedFastaDir = createCompressedFastaDir(residualFasta)

    residualWorkflow(compressedFastaDir.fastaDir, "residual")
}
