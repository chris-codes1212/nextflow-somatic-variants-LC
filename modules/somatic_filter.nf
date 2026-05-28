// modules/somatic_filter.nf
// Filters somatic variants by removing germline variants present in normal tissue
// Uses bcftools isec --complement, same strategy as original class pipeline
// This isolates tumor-specific (somatic) mutations

process FILTER_SOMATIC {

    tag "${patient_id}"
    label 'medium'

    publishDir { "${params.outdir}/somatic_variants/${patient_id}" }, mode: 'copy'

    input:
    tuple val(patient_id),
          path(tumor_bcf),
          path(normal_bcf)

    output:
    tuple val(patient_id),
          path("${patient_id}_somatic.vcf"),
          emit: somatic_vcf

    script:
    """
    # Index both BCF files
    bcftools index ${tumor_bcf}
    bcftools index ${normal_bcf}

    # Extract variants present in tumor but NOT in normal (somatic only)
    # --complement: outputs records in tumor_bcf NOT present in normal_bcf
    bcftools isec \\
        --threads ${task.cpus} \\
        --complement \\
        ${tumor_bcf} \\
        ${normal_bcf} \\
        -w 1 \\
        -o ${patient_id}_somatic.vcf

    echo "Somatic variant count for ${patient_id}:"
    grep -v "^#" ${patient_id}_somatic.vcf | wc -l
    """
}
