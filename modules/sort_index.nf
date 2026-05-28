// modules/sort_index.nf
// Sorts and indexes tumor and normal BAM files using samtools

process SORT_INDEX_BAM {

    tag "${patient_id}"
    label 'medium'

    publishDir { "${params.outdir}/sorted_bam/${patient_id}" }, mode: 'copy'

    input:
    tuple val(patient_id),
          path(tumor_bam),
          path(normal_bam)

    output:
    tuple val(patient_id),
          path("${patient_id}_tumor_sorted.bam"),
          path("${patient_id}_tumor_sorted.bam.bai"),
          path("${patient_id}_normal_sorted.bam"),
          path("${patient_id}_normal_sorted.bam.bai"),
          emit: sorted_bam

    script:
    """
    echo "Sorting tumor BAM for ${patient_id}"
    samtools sort \\
        -@ ${task.cpus} \\
        -o ${patient_id}_tumor_sorted.bam \\
        ${tumor_bam}
    samtools index ${patient_id}_tumor_sorted.bam

    echo "Sorting normal BAM for ${patient_id}"
    samtools sort \\
        -@ ${task.cpus} \\
        -o ${patient_id}_normal_sorted.bam \\
        ${normal_bam}
    samtools index ${patient_id}_normal_sorted.bam

    # Flagstat for QC
    samtools flagstat ${patient_id}_tumor_sorted.bam  > ${patient_id}_tumor_flagstat.txt
    samtools flagstat ${patient_id}_normal_sorted.bam > ${patient_id}_normal_flagstat.txt
    """
}
