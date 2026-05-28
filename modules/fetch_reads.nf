// modules/fetch_reads.nf
// Downloads paired tumor and normal reads from NCBI SRA

process FETCH_READS {

    tag "${patient_id}"
    label 'low'

    publishDir { "${params.outdir}/raw_reads/${patient_id}" }, mode: 'copy'

    input:
    tuple val(patient_id), val(tumor_SRA), val(normal_SRA)

    output:
    tuple val(patient_id),
          path("tumor/${tumor_SRA}_1.fastq.gz"),
          path("tumor/${tumor_SRA}_2.fastq.gz"),
          path("normal/${normal_SRA}_1.fastq.gz"),
          path("normal/${normal_SRA}_2.fastq.gz"),
          emit: reads

    script:
    """
    # Configure SRA toolkit for non-interactive container use
    mkdir -p \${HOME}/.ncbi
    printf '/LIBS/GUID = "00000000-0000-0000-0000-000000000001"\n/repository/user/main/public/cache-enabled = "false"\n/repository/user/main/public/root = "."\n' \
        > \${HOME}/.ncbi/user-settings.mkfg

    mkdir -p tumor normal

    echo "Fetching tumor reads: ${tumor_SRA}"
    fasterq-dump ${tumor_SRA} --outdir tumor --split-files --threads ${task.cpus}
    gzip tumor/${tumor_SRA}_1.fastq
    gzip tumor/${tumor_SRA}_2.fastq

    echo "Fetching normal reads: ${normal_SRA}"
    fasterq-dump ${normal_SRA} --outdir normal --split-files --threads ${task.cpus}
    gzip normal/${normal_SRA}_1.fastq
    gzip normal/${normal_SRA}_2.fastq
    """
}
