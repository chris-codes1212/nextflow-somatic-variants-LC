#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// ============================================================
// nextflow-somatic-variant-demo
// Somatic variant calling pipeline for paired tumor/normal RNA-seq
// Modernized from a class project into Nextflow DSL2
// ============================================================

log.info """
    ================================================
     SOMATIC VARIANT CALLING PIPELINE (DSL2)
    ================================================
     reference   : ${params.reference}
     sample_sheet: ${params.sample_sheet}
     outdir      : ${params.outdir}
     gene_panel  : ${params.gene_panel}
    ================================================
""".stripIndent()

// ------------------------------------------------------------
// Include modules
// ------------------------------------------------------------
include { FETCH_READS        } from './modules/fetch_reads'
include { TRIM_READS         } from './modules/trim'
include { ALIGN_READS        } from './modules/align'
include { SORT_INDEX_BAM     } from './modules/sort_index'
include { CALL_VARIANTS      } from './modules/variant_call'
include { FILTER_SOMATIC     } from './modules/somatic_filter'
include { GENE_PANEL_REPORT  } from './modules/gene_panel_analysis'
include { MULTIQC            } from './modules/multiqc'

// ------------------------------------------------------------
// Main workflow
// ------------------------------------------------------------
workflow {

    // Read sample sheet: patient_id, tumor_SRA, normal_SRA
    Channel
        .fromPath(params.sample_sheet)
        .splitCsv(header: true)
        .map { row -> tuple(row.patient_id, row.tumor_SRA, row.normal_SRA) }
        .set { samples_ch }

    // 1. Fetch reads from SRA for tumor and normal
    FETCH_READS(samples_ch)

    // 2. Trim reads
    TRIM_READS(FETCH_READS.out.reads)

    // 3. Align to reference
    ALIGN_READS(TRIM_READS.out.trimmed, params.reference)

    // 4. Sort and index BAM files
    SORT_INDEX_BAM(ALIGN_READS.out.bam)

    // 5. Call variants (tumor and normal separately)
    CALL_VARIANTS(SORT_INDEX_BAM.out.sorted_bam, params.reference)

    // 6. Filter somatic variants (tumor - normal)
    FILTER_SOMATIC(CALL_VARIANTS.out.bcf)

    // 7. Gene panel analysis
    GENE_PANEL_REPORT(FILTER_SOMATIC.out.somatic_vcf, params.gene_panel)

    // 8. MultiQC report
    MULTIQC(
        TRIM_READS.out.reports.collect(),
        ALIGN_READS.out.logs.collect()
    )
}
