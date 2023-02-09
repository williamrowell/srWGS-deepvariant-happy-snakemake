shards = [f"{x:05}" for x in range(config["N_SHARDS"])]


rule deepvariant_make_examples:
    input:
        bam="aligned/{condition}.bam",
        bai="aligned/{condition}.bam.bai",
        reference=config["ref"]["fasta"],
    output:
        tfrecord=temp(
            f"conditions/{{condition}}/deepvariant/examples/examples.tfrecord-{{shard}}-of-{config['N_SHARDS']:05}.gz"
        ),
    log:
        f"conditions/{{condition}}/logs/deepvariant/make_examples/{{shard}}-of-{config['N_SHARDS']:05}.log",
    container:
        f"docker://google/deepvariant:{config['DEEPVARIANT_VERSION']}"
    params:
        vsc_min_fraction_snps="0.05",
        vsc_min_fraction_indels="0.05",
        shard=lambda wildcards: wildcards.shard,
    shell:
        f"""
        (/opt/deepvariant/bin/make_examples \
            --vsc_min_fraction_indels {{params.vsc_min_fraction_indels}} \
            --vsc_min_fraction_snps {{params.vsc_min_fraction_snps}} \
            --mode calling \
            --channels insert_size \
            --ref {{input.reference}} \
            --reads {{input.bam}} \
            --examples conditions/{{wildcards.condition}}/deepvariant/examples/examples.tfrecord@{config['N_SHARDS']}.gz \
            --task {{wildcards.shard}}) > {{log}} 2>&1
        """


rule deepvariant_call_variants_gpu:
    input:
        lambda wildcards: expand(
            f"conditions/{wildcards.condition}/deepvariant/examples/examples.tfrecord-{{shard}}-of-{config['N_SHARDS']:05}.gz",
            shard=shards,
        ),
    output:
        temp(
            "conditions/{condition}/deepvariant/{condition}.call_variants_output.tfrecord.gz"
        ),
    log:
        "conditions/{condition}/logs/deepvariant/call_variants/{condition}.log",
    container:
        f"docker://google/deepvariant:{config['DEEPVARIANT_VERSION']}"
    params:
        model="/opt/models/wgs/model.ckpt",
    threads: 8
    shell:
        f"""
        (/opt/deepvariant/bin/call_variants \
            --outfile {{output}} \
            --examples conditions/{{wildcards.condition}}/deepvariant/examples/examples.tfrecord@{config['N_SHARDS']}.gz \
            --checkpoint {{params.model}}) > {{log}} 2>&1
        """


rule deepvariant_postprocess_variants:
    input:
        tfrecord="conditions/{condition}/deepvariant/{condition}.call_variants_output.tfrecord.gz",
        reference=config["ref"]["fasta"],
    output:
        vcf="conditions/{condition}/deepvariant/{condition}.deepvariant.vcf.gz",
        vcf_index="conditions/{condition}/deepvariant/{condition}.deepvariant.vcf.gz.tbi",
        report="conditions/{condition}/deepvariant/{condition}.deepvariant.visual_report.html",
    log:
        "conditions/{condition}/logs/deepvariant/postprocess_variants/{condition}.log",
    container:
        f"docker://google/deepvariant:{config['DEEPVARIANT_VERSION']}"
    threads: 4
    shell:
        f"""
        (/opt/deepvariant/bin/postprocess_variants \
            --ref {{input.reference}} \
            --infile {{input.tfrecord}} \
            --outfile {{output.vcf}}) > {{log}} 2>&1
        """


# rule deepvariant_bcftools_stats:
#     input:
#         "conditions/{condition}/deepvariant/{condition}.deepvariant.vcf.gz",
#     output:
#         "conditions/{condition}/deepvariant/{condition}.deepvariant.vcf.stats.txt",
#     log:
#         "conditions/{condition}/logs/bcftools/stats/{condition}.deepvariant.vcf.log",
#     params:
#         f"--fasta-ref {config['ref']['fasta']} --apply-filters PASS -s {config['sample']}",
#     threads: 4
#     conda:
#         "envs/bcftools.yaml"
#     shell:
#         "(bcftools stats --threads 3 {params} {input} > {output}) > {log} 2>&1"

