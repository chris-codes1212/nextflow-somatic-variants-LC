// modules/trim.nf
// Trims paired tumor and normal reads using Trim Galore
// Trim Galore wraps cutadapt (used in original class pipeline) and adds FastQC

process TRIM_READS {

    tag "${patient_id}"
    label 'medium'

    publishDir "${params.outdir}/trimmed/${patient_id}", mode: 'copy'

    input:
    tuple val(patient_id),
          path(tumor_r1), path(tumor_r2),
          path(normal_r1), path(normal_r2)

    output:
    tuple val(patient_id),
          path("tumor/*_val_1.fq.gz"),
          path("tumor/*_val_2.fq.gz"),
          path("normal/*_val_1.fq.gz"),
          path("normal/*_val_2.fq.gz"),
          emit: trimmed
    path "tumor/*_fastqc.{zip,html}", emit: reports
    path "normal/*_fastqc.{zip,html}", emit: reports

    script:
    """
    mkdir -p tumor normal

    echo "Trimming tumor reads for ${patient_id}"
    trim_galore \\
        --paired \\
        --quality 20 \\
        --length 80 \\
        --cores ${task.cpus} \\
        --fastqc \\
        --output_dir tumor \\
        ${tumor_r1} ${tumor_r2}

    echo "Trimming normal reads for ${patient_id}"
    trim_galore \\
        --paired \\
        --quality 20 \\
        --length 80 \\
        --cores ${task.cpus} \\
        --fastqc \\
        --output_dir normal \\
        ${normal_r1} ${normal_r2}
    """
}
