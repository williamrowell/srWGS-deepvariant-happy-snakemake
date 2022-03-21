import re
from pathlib import Path


configfile: "workflow/config.yaml"


## prefix every task command with:
# set -o pipefail  # trace ERR through pipes
# umask 002  # group write permissions
# export TMPDIR={config['tmpdir']}  # configure temp directory
# export SINGULARITY_BINDPATH={config['tmpdir']}  # bind temp directory
shell.prefix(
    f"set -o pipefail; umask 002; export TMPDIR={config['tmpdir']}; export SINGULARITY_BINDPATH={config['tmpdir']}; "
)

# scan smrtcells/ready for inputs
# uBAMs have priority over FASTQs if both are available
# samples and files are expected to match one of the following patterns:
condition_pattern = re.compile(r"aligned/(?P<condition>[A-Za-z0-9_-]+).bam")
condition_list = []
for infile in Path("aligned").glob("**/*.bam"):
    condition_match = condition_pattern.search(str(infile))
    if condition_match:
        # create a dict-of-dict to link samples to movie context to uBAM filenames
        condition_list.append(condition_match.group("condition"))

# build a list of targets
targets = []


include: "rules/deepvariant.smk"
include: "rules/happy.smk"


targets.extend(
    [
        f"conditions/{condition}/deepvariant/{condition}.deepvariant.{suffix}"
        for condition in condition_list
        for suffix in [
            "vcf.gz",
            "vcf.gz.tbi",
            "visual_report.html",
            "vcf.stats.txt",
        ]
    ]
)
targets.extend(
    [
        f"conditions/{condition}/happy/{ver}.{suffix}"
        for condition in condition_list
        for ver in ["all", "cmrg"]
        for suffix in ["summary.csv", "extended.csv"]
    ]
)

print(targets)

rule all:
    input:
        targets,
