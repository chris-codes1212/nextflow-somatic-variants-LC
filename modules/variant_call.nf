// modules/variant_call.nf
// Calls variants in tumor and normal BAMs using bcftools mpileup/call
// Mirrors approach from original class pipeline

process CALL_VARIANTS {

    tag "${patient_id}"
    label 'high'

    publishDir { "${params.outdir}/variants/${patient_id}" }, mode: 'copy'

    input:
    tuple val(patient_id),
          path(tumor_bam),  path(tumor_bai),
          path(normal_bam), path(normal_bai)
    path reference

    output:
    tuple val(patient_id),
          path("${patient_id}_tumor.bcf"),
          path("${patient_id}_normal.bcf"),
          emit: bcf

    script:
    """
    echo "Calling variants in tumor tissue for ${patient_id}"
    bcftools mpileup \\
        --threads ${task.cpus} \\
        -Ou \\
        -f ${reference} \\
        ${tumor_bam} \\
    | bcftools call \\
        --threads ${task.cpus} \\
        -mv \\
        -Ob \\
        -o ${patient_id}_tumor.bcf

    echo "Calling variants in normal tissue for ${patient_id}"
    bcftools mpileup \\
        --threads ${task.cpus} \\
        -Ou \\
        -f ${reference} \\
        ${normal_bam} \\
    | bcftools call \\
        --threads ${task.cpus} \\
        -mv \\
        -Ob \\
        -o ${patient_id}_normal.bcf
    """
}
