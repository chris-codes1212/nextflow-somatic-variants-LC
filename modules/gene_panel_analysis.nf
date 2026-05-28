// modules/gene_panel_analysis.nf
// Maps somatic variants to a cancer gene panel (EGFR, KRAS, BRAF, etc.)
// Python logic modernized from variant_analysis.py in original class project

process GENE_PANEL_REPORT {

    tag "${patient_id}"
    label 'low'

    publishDir "${params.outdir}/gene_panel/${patient_id}", mode: 'copy'

    input:
    tuple val(patient_id), path(somatic_vcf)
    path gene_panel_json

    output:
    path "${patient_id}_mutation_profile.csv",  emit: csv
    path "${patient_id}_mutation_report.txt",   emit: report

    script:
    """
    #!/usr/bin/env python3

    import vcf
    import csv
    import json
    from collections import defaultdict

    # Load gene panel from JSON (externalized from hardcoded dict in original script)
    with open("${gene_panel_json}", "r") as f:
        gene_panel = json.load(f)

    # Build reverse lookup: refseq_id -> gene_name
    refseq_to_gene = {}
    for gene, transcripts in gene_panel.items():
        for t in transcripts:
            refseq_to_gene[t] = gene

    # Parse somatic VCF
    vcf_reader = vcf.Reader(open("${somatic_vcf}", "r"))

    mutations      = []
    gene_hit_count = defaultdict(int)

    for record in vcf_reader:
        gene = refseq_to_gene.get(record.CHROM)
        if gene:
            gene_hit_count[gene] += 1
            mutations.append({
                "patient":    "${patient_id}",
                "gene":       gene,
                "refseq_id":  record.CHROM,
                "position":   record.POS,
                "reference":  str(record.REF),
                "alteration": ",".join(str(a) for a in record.ALT),
                "qual":       record.QUAL,
            })

    # Write per-mutation CSV
    with open("${patient_id}_mutation_profile.csv", "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["patient", "gene", "refseq_id",
                                               "position", "reference", "alteration", "qual"])
        writer.writeheader()
        writer.writerows(mutations)

    # Write summary report
    with open("${patient_id}_mutation_report.txt", "w") as f:
        f.write(f"Mutation Report: ${patient_id}\\n")
        f.write("=" * 50 + "\\n\\n")
        f.write(f"Total somatic variants in gene panel: {len(mutations)}\\n\\n")
        f.write("Hits per gene:\\n")
        for gene, count in sorted(gene_hit_count.items(), key=lambda x: -x[1]):
            f.write(f"  {gene}: {count} variant(s)\\n")
        f.write("\\nDetailed mutations:\\n")
        for m in mutations:
            f.write(f"  {m['gene']} | {m['refseq_id']} | pos:{m['position']} "
                    f"| {m['reference']} -> {m['alteration']} | QUAL:{m['qual']}\\n")

    print(f"Gene panel analysis complete for ${patient_id}: {len(mutations)} variants found")
    """
}
