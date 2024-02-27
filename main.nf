#!/usr/bin/env nextflow
//base folder for seqence inputs

params.in = "$baseDir/in/*.fas.gz"
params.outdir = "$baseDir/out"
params.gene_result_column = 1


//this is the folder structure of bactopia output
params.input_structure = "**/main/assembler/*.fna.gz"

process PLASMIDFINDER{
    publishDir "$baseDir/out"

    input:
    file fasta

    output:
    path("*.json")                 , emit: json
    path("*.txt")                  , emit: txt
    path("*.tsv")                  , emit: tsv
    path("*-hit_in_genome_seq.fsa"), emit: genome_seq
    path("*-plasmid_seqs.fsa")     , emit: plasmid_seq

    script:
    def prefix = fasta.getSimpleName()
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    def fasta_name = fasta.getName().replace(".gz", "")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    plasmidfinder.py -i $fasta_name -x -p /plasmidfinderdb -o ./

    # Rename hard-coded outputs with prefix to avoid name collisions
    mv data.json ${prefix}.json
    mv results.txt ${prefix}.txt
    mv results_tab.tsv ${prefix}.tsv
    mv Hit_in_genome_seq.fsa ${prefix}-hit_in_genome_seq.fsa
    mv Plasmid_seqs.fsa ${prefix}-plasmid_seqs.fsa
    """
}

process CSV{
    debug true

    publishDir "$baseDir/out", mode: 'copy'

    input:
    val tables

    output:
    path 'plasmid_results.csv'

    exec:
    gene_list = []
    results = [:]
    tables.each { table ->
        sample_genes = []

        table
            .splitCsv(header:true,sep:"\t")
            .each {row -> sample_genes.push(row["Accession number"])}

        sample_genes.unique()
        gene_list += sample_genes
        sample_name = table.getSimpleName()
        results[sample_name] = sample_genes
    }
    result_table = ""
    gene_list.unique().sort()
    results = results.sort()
    results.each{ sample_name, genes ->
        result_row = []
        gene_list.each { gene ->
            if (genes.contains(gene)){
                result_row += 1
            } else{
                result_row += 0
            }
        }
        result_row.push(sample_name)
        result_table += result_row.join(',') + "\n"
    }

    gene_list.push('Isolate')
    headers = gene_list.join(',') + "\n"
    result_table = headers + result_table

    csv_file = task.workDir.resolve('plasmid_results.csv')
    csv_file.text = result_table
}

workflow{
    input_seqs = Channel
        .fromPath(params.in)

    PLASMIDFINDER(input_seqs)
    CSV(PLASMIDFINDER.out.tsv.collect())
}
