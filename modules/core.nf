#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include {bestRepsSelfDiamond as coreBestRepsToCoreDiamond;
         bestRepsSelfDiamond as residualBestRepsToCoreAndResidualDiamond;
         bestRepsSelfDiamond as coreBestRepsToResidualDiamond;
         calculateGroupResults; collectDiamondSimilaritesPerGroup
} from './shared.nf'

/**
* Run orthofinder to compute groups
*
* @param blasts:  precomputed diamond similarities for all pairs
* @param orthofinderWorkingDir is the direcotry with the diamond indexes and fasta files
* @return N0.tsv is the resulting file from orthofinder
* @return Results (catch all results)
*/

process computeGroups {
  container = 'veupathdb/orthofinder'

  input:
    path blasts
    path orthofinderWorkingDir

  output:
    path 'Results/Phylogenetic_Hierarchical_Orthogroups/N0.tsv', emit: orthologgroups
    path 'Results', emit: results

  script:
    template 'computeGroups.bash'
}

process publishOFResults {
  container = 'veupathdb/orthofinder'
  
  publishDir "$params.outputDir", mode: "copy"

  input:
    path 'OrthoFinderResults'
  
  output:
    path 'Results'

  '''
  cp -r OrthoFinderResults Results
  '''
}

/**
* make one file containing all ortholog groups per species
* @param species
* @param speciesMapping is the NEW Species mapping from orthofinder setup step (current run)
* @param sequenceMapping is the NEW Sequence mapping from orthofinder setup step (current run)
* @param orthologgroups
* @param buildVersion
* @return orthologs
* @return singletons
*/
process splitOrthologGroupsPerSpecies {
    container = 'veupathdb/orthofinder'

    input:
    val species
    path speciesMapping
    path sequenceMapping
    path orthologgroups
    val buildVersion

    output:
    path '*.orthologs', emit: orthologs
    path "*.singletons", emit: singletons

    script:
    template 'splitOrthologGroupsPerSpecies.bash'
}

/**
* One file per orthologgroup with all diamond output for that group
* @return orthogroupblasts (sim files per group)
*/

process makeOrthogroupDiamondFile {
  container = 'veupathdb/orthofinder'

  input:
    tuple val(target), val(queries)
    path blasts
    path orthologs

  output:
    path '*.txt.sorted', emit: blastsByOrthogroup

  script:
    template 'makeOrthogroupDiamondFile.bash'
}


process splitBlastsIntoGroupsFiles {
  container = 'veupathdb/orthofinder'

  input:
    path blastsByOrthogroup

  output:
    path '*.sim', emit: groupBlastResults

  script:
    template 'splitBlastsIntoGroupsFiles.bash'
}



/**
* combine species singletons file. this will create new ortholog group IDS based on
* the last row in the orthologgroups file.  the resulting id will also include the version
*/

process makeFullSingletonsFile {
  container = 'veupathdb/orthofinder'

  input:
    path singletonFiles
    path orthogroups
    val buildVersion

  output:
    path 'singletonsFull.dat'

  script:
    template 'makeFullSingletonsFile.bash'
}

/**
* write singleton files with original seq ids in place of internal ids
*/

process translateSingletonsFile {
  container = 'veupathdb/orthofinder'

  input:
    path singletonsFile
    path sequenceMapping

  output:
    path 'translatedSingletons.dat'

  script:
    template 'translateSingletonsFile.bash'
}


/**
* write groups file for use in peripheral wf or to be loaded into relational db
*/
process reformatGroupsFile {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path groupsFile
    path translatedSingletons
    val buildVersion
    val coreOrResidual

  output:
    path 'reformattedGroups.txt'

  script:
    template 'reformatGroupsFile.bash'
}

/**
*  for each group, determine which sequence has the lowest average evalue
*/
process findBestRepresentatives {
  container = 'veupathdb/orthofinder'

  input:
    path groupData
    path missingGroups
    path groupMapping
    path sequenceMapping

  output:
    path 'best_representative.txt'

  script:
    template 'findBestRepresentatives.bash'
}


/**
*  orthofinder outputs a line "empty" which we don't care about
*/

process removeEmptyGroups {
    input:
    path singletons
    path bestReps

    output:
    path "unique_best_representative.txt"

    script:
    """
    touch allReps.txt
    cat $bestReps >> allReps.txt
    cat $singletons >> allReps.txt
    grep -v '^empty' allReps.txt > unique_best_representative.txt
    """
}

/**
*  grab all best representative sequences.  use the group id as the defline
*/
process makeBestRepresentativesFasta {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path bestRepresentatives
    path orthofinderWorkingDir
    val isResidual

  output:
    path 'bestReps.fasta'

  script:
    template 'makeBestRepresentativesFasta.bash'
}


/**
*  Translate best rep file to hold actual sequenceIds, not OF internal ids
*/
process translateBestRepsFile {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path sequenceMapping
    path bestReps
    val isResidual

  output:
    path 'bestReps.txt'

  script:
    template 'translateBestRepsFile.bash'
}


/**
*  In batches of ortholog groups, Read the file of bestReps (group->seq)
*  and filter the matching group.sim file.  use the singletons file
*  to exclude groups with only one sequence.
*
*/

process filterSimilaritiesByBestRepresentative {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/coreSimilarityToBestReps", mode: "copy"
  afterScript "rm *.sim"

  input:
    path groupData
    path bestReps
    path singletons
    path missingGroups

  output:
    path '*.tsv'

  script:
    template 'filterSimilaritiesByBestRepresentative.bash'
}


process createEmptyDir {
  container = 'veupathdb/orthofinder'

  input:
    path speciesMapping

  output:
    path 'emptyDir'

  script:
    """
    mkdir emptyDir
    """
}

/**
* combine the core and residual fasta files containing best representative sequences
*
*/
process mergeCoreAndResidualBestReps {
  container = 'veupathdb/orthofinder'

  input:
    path residualBestReps
    // Avoid file name collision
    path 'coreBestReps.fasta'

  output:
    path 'bestRepsFull.fasta'

  script:
    """
    cp $residualBestReps bestRepsFull.fasta
    cat coreBestReps.fasta >> bestRepsFull.fasta
    """
}

/**
* combine the core and residual best rep similar groups files
*
*/
process mergeCoreAndResidualSimilarGroups {
  container = 'veupathdb/orthofinder'

  publishDir "$params.outputDir/", mode: "copy"

  input:
    // Avoid file name collision
    path 'coreSimilarGroups'
    path 'coreAndResidualSimilarGroups'
    path 'residualSimilarGroups'

  output:
    path 'all_best_reps_self_blast.txt'

  script:
    """
    cp coreSimilarGroups all_best_reps_self_blast.txt
    cat coreAndResidualSimilarGroups >> all_best_reps_self_blast.txt
    cat residualSimilarGroups >> all_best_reps_self_blast.txt
    """
}

/**
* checkForMissingGroups
*
*/
process checkForMissingGroups {
  container = 'veupathdb/orthofinder'

  input:
    path allDiamondSimilarities
    val buildVersion

  output:
    path 'missingGroups.txt'

  script:
    """
    checkForMissingGroups.pl . $buildVersion
    """
}

/**
* take a list and find all possible pairwise combinations.
* organize the combinations so we can send reasonably sized chunks as individual jobs (chunkSize).
*
* Example: listToPairwiseComparisons(channel.of(1..3).collect(), 2).view();
* [1, [1, 2]]
* [2, [1, 2]]
* [3, [1, 2]]
* [1, [3]]
* [2, [3]]
* [3, [3]]
*/
def listToPairwiseComparisons(list, chunkSize) {
    return list.map { it -> [it,it].combinations().findAll(); }
        .flatMap { it }
        .groupTuple(size: chunkSize, remainder:true)

}

/**
* The speciesMapping file comes directly from orthoFinder.  This function will
* return a list from either the first or second column
*/
def speciesFileToList(speciesMapping, index) {
    return speciesMapping
        .splitText(){it.tokenize(': ')[index]}
        .map { it.replaceAll("[\n\r]", "") }
        .toList()
}



workflow coreOrResidualWorkflow {
  take:
    inputFile
    sequenceMapping
    speciesMapping
    diamondResults
    workingDir
    coreOrResidual

  main:

    // get lists of species names and internal ids
    speciesIds = speciesFileToList(speciesMapping, 0);
    speciesNames = speciesFileToList(speciesMapping, 1);

    // make tuple object for processing pairwise combinations of species
    speciesPairsAsTuple = listToPairwiseComparisons(speciesIds, 250);

    //make one file per species containing all ortholog groups for that species
    speciesOrthologs = splitOrthologGroupsPerSpecies(speciesNames.flatten(),
                                                     speciesMapping.collect(),
                                                     sequenceMapping.collect(),
                                                     inputFile.collect(),
                                                     params.buildVersion);

    // per species, make One file all diamond similarities for that group
    diamondSimilaritiesPerGroup = makeOrthogroupDiamondFile(speciesPairsAsTuple,
                                                            diamondResults.collect(),
                                                            speciesOrthologs.orthologs.collect())
							     
    singleFileOfSimilarities = diamondSimilaritiesPerGroup.blastsByOrthogroup.flatten().collectFile(name: 'groupsDiamondFile.txt')

    allDiamondSimilaritiesPerGroup = splitBlastsIntoGroupsFiles(singleFileOfSimilarities).flatten()

    // sub workflow to process diamondSimlarities for best representatives and group stats
    bestRepresentativesAndStats(workingDir,
                                sequenceMapping,
                                inputFile.collect(),
                                allDiamondSimilaritiesPerGroup,
                                speciesOrthologs.singletons,
                                coreOrResidual)
}


workflow bestRepresentativesAndStats {
    take:
    setupOrthofinderWorkingDir
    setupSequenceMapping
    orthofinderGroupResultsOrthologgroups
    allDiamondSimilaritiesPerGroup
    speciesOrthologsSingletons
    coreOrResidual

    main:
    
    // make a collection containing all group similarity files
    allDiamondSimilarities = allDiamondSimilaritiesPerGroup.collect()

    missingGroups = checkForMissingGroups(allDiamondSimilarities,params.buildVersion)

    // make a collection of singletons files (one for each species)
    singletonFiles = speciesOrthologsSingletons.collect()

    // combine all singletons and assign a group id
    singletonsFull = makeFullSingletonsFile(singletonFiles, orthofinderGroupResultsOrthologgroups, params.buildVersion).collectFile()

    // in batches, process group similarity files and determine best representative for each group
    bestRepresentatives = findBestRepresentatives(allDiamondSimilaritiesPerGroup.collate(250),missingGroups.collect(),orthofinderGroupResultsOrthologgroups.collect(),setupSequenceMapping.collect())

    allBestRepresentatives = bestRepresentatives.flatten().collectFile()

    // collect File of best representatives
    combinedBestRepresentatives = removeEmptyGroups(singletonsFull, allBestRepresentatives)

    // make best rep file with actual sequence Ids
    translateBestRepsFile(setupSequenceMapping, combinedBestRepresentatives, coreOrResidual)

    // fasta file with all seqs for best representative sequence.
    // (defline contains group id like:  OG_XXXX)
    bestRepresentativeFasta = makeBestRepresentativesFasta(combinedBestRepresentatives,
                                                           setupOrthofinderWorkingDir, coreOrResidual)

    // in batches of bestReps, filter the group.sim file to create a file per group with similarities where the query seq is the bestRep
    // collect up resulting files
    groupResultsOfBestRep = filterSimilaritiesByBestRepresentative(allDiamondSimilarities,
                                                                   combinedBestRepresentatives.splitText( by: 10000, file: true ),
                                                                   singletonsFull.collect(),
								   missingGroups).collect()

    // split bestRepresentative into chunks for parallel processing
    bestRepSubset = bestRepresentativeFasta.splitFasta(by:1000, file:true)

    if (coreOrResidual == 'core') {

        // in batches of group similarity files filted by best representative, calculate group stats from evalues (min, max, median, ...)
        calculateGroupResults(groupResultsOfBestRep.flatten().collate(250), 10, false)
            .collectFile(name: "core_stats.txt", storeDir: params.outputDir + "/groupStats" )

        // run diamond for core best representatives compared to core bestRep DB
        // this will be used to find similar ortholog groups
        bestRepsSelfDiamondResults = coreBestRepsToCoreDiamond(bestRepSubset, bestRepresentativeFasta)
            .collectFile(name: "core_best_reps_self_blast.txt", storeDir: params.outputDir );

        translatedSingletonsFile = translateSingletonsFile(singletonsFull,
                                                           setupSequenceMapping)

        // Final output format of groups. Sent to peripheral workflow to identifiy which sequences are contained in which group in the core.
        reformatGroupsFile(orthofinderGroupResultsOrthologgroups,
                           translatedSingletonsFile,
                           params.buildVersion,
			   coreOrResidual)
    }
}
