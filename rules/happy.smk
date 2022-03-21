rule happy_benchmark_deepvariant:
    input:
        ref = config['reference']['fasta'],
        query_vcf = rules.deepvariant_postprocess_variants.output.vcf,
        query_tbi = rules.deepvariant_postprocess_variants.output.vcf_index,
        bench_vcf = lambda wc: config['happy'][wc.ver]['vcf'],
        bench_bed = lambda wc: config['happy'][wc.ver]['bed'],
        strats = config['stratifications'],
        sdf = config['sdf'],
    output:
        "conditions/{condition}/happy/{ver}.extended.csv",
        "conditions/{condition}/happy/{ver}.metrics.json.gz",
        "conditions/{condition}/happy/{ver}.roc.all.csv.gz",
        "conditions/{condition}/happy/{ver}.roc.Locations.INDEL.csv.gz",
        "conditions/{condition}/happy/{ver}.roc.Locations.INDEL.PASS.csv.gz",
        "conditions/{condition}/happy/{ver}.roc.Locations.SNP.csv.gz",
        "conditions/{condition}/happy/{ver}.roc.Locations.SNP.PASS.csv.gz",
        "conditions/{condition}/happy/{ver}.runinfo.json",
        "conditions/{condition}/happy/{ver}.summary.csv",
        "conditions/{condition}/happy/{ver}.vcf.gz",
        "conditions/{condition}/happy/{ver}.vcf.gz.tbi",
    log: "conditions/{condition}/logs/happy_benchmark_deepvariant.{ver}.log"
    container: "docker://pkrusche/hap.py:latest"
    params:
        prefix = "conditions/{condition}/happy/{ver}"
    threads: 12
    shell:
        """
        (/opt/hap.py/bin/hap.py \
            --threads {threads} \
            -r {input.ref} -f {input.bench_bed} \
            -o {params.prefix} \
            --engine=vcfeval --engine-vcfeval-template {input.sdf} \
            --stratification {input.strats} \
            {input.bench_vcf} {input.query_vcf}) > {log} 2>&1
        """
