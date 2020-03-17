import itertools
import urllib

ALL_RAW = list(itertools.chain.from_iterable(
    [expand("data/{dataset}/{sample}",
            dataset = it[0], sample = it[1]["samples"])
     for it in SAMPLES_BY_DATASET.items()]
))

ALL_MZML = [samp.rstrip(".raw") + ".mzML" for samp in ALL_RAW]

rule finalize_preprocess:
    input:
        ALL_MZML
    output:
        touch("data/files_preprocessed.flag")

rule convert_raw:
    input:
        "data/{dataset}/{basename}.raw"
    output:
        "data/{dataset}/{basename}.mzML"
    conda:
        SNAKEMAKE_DIR + "/envs/raw_parser.yaml"
    group:
        "preprocess"
    shell:
        """
        ThermoRawFileParser.sh -i {input} \
                               -b {output} \
                               -f 2
        """

rule download_raw:
    output:
        "data/{dataset}/{basename}.raw"
    params:
        src = lambda wildcards: SAMPLES_BY_DATASET[wildcards.dataset]["ftp"] + wildcards.basename + ".raw"
    group:
        "preprocess"
    shell:
        """
        curl {params.src} --output {output}
        """
