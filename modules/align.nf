// modules/align.nf
// Aligns trimmed paired reads to reference using BWA-MEM2
// Upgrade from bbmap used in original class pipeline —
// BWA-MEM2 is faster and more widely cited in somatic variant calling literature

process ALIGN_READS {

    tag "${patient_id}"
    label 'high'

    publishDir { "${params.outdir}/aligned/${patient_id}" }, mode: 'copy'

    input:
    tuple val(patient_id),
          path(tumor_r1), path(tumor_r2),
          path(normal_r1), path(normal_r2)
    path reference

    output:
    tuple val(patient_id),
          path("${patient_id}_tumor.bam"),
          path("${patient_id}_normal.bam"),
          emit: bam
    path "*.log", emit: logs

    script:
    """
    # Index reference if not already indexed
    if [ ! -f ${reference}.bwt.2bit.64 ]; then
        echo "Indexing reference..."
        bwa-mem2 index ${reference}
    fi

    echo "Aligning tumor reads for ${patient_id}"
    bwa-mem2 mem \\
        -t ${task.cpus} \\
        -R "@RG\\tID:${patient_id}_tumor\\tSM:${patient_id}\\tPL:ILLUMINA\\tLB:tumor" \\
        ${reference} \\
        ${tumor_r1} ${tumor_r2} \\
        2> ${patient_id}_tumor_bwa.log \\
        | samtools view -bS - > ${patient_id}_tumor.bam

    echo "Aligning normal reads for ${patient_id}"
    bwa-mem2 mem \\
        -t ${task.cpus} \\
        -R "@RG\\tID:${patient_id}_normal\\tSM:${patient_id}\\tPL:ILLUMINA\\tLB:normal" \\
        ${reference} \\
        ${normal_r1} ${normal_r2} \\
        2> ${patient_id}_normal_bwa.log \\
        | samtools view -bS - > ${patient_id}_normal.bam
    """
}
