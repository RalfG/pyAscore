ALL_SEARCH = list(itertools.chain.from_iterable(
    [expand("search/{dataset}/{sample}",
            dataset = it[0], sample = it[1]["samples"])
     for it in SAMPLES_BY_DATASET.items()]
))

ALL_SEARCH = [samp.rstrip(".raw") + ".percolator.log.txt" for samp in ALL_SEARCH]

rule finalize_database_search:
    input:
        ALL_SEARCH
    output:
        touch("search/files_searched.flag")

rule percolator_scoring:
    input:
        "search/{dataset}/{basename}.comet.target.pep.xml"
    output:
        "search/{dataset}/{basename}.percolator.target.pep.xml",
        "search/{dataset}/{basename}.percolator.decoy.pep.xml",
        "search/{dataset}/{basename}.percolator.target.psms.txt",
        "search/{dataset}/{basename}.percolator.decoy.psms.txt",
        "search/{dataset}/{basename}.percolator.log.txt"
    params:
        fileroot = "{basename}",
        output_dir = "search/{dataset}/"
    conda:
        SNAKEMAKE_DIR + "/envs/crux.yaml"
    group:
        "database_search"
    shell:
        """
        crux percolator --fileroot {params.fileroot} \
                        --output-dir {params.output_dir} \
                        --only-psms T \
                        --pepxml-output T \
                        --top-match 1 \
                        --overwrite T \
                        {input}
        """

COMET_PARAM_MAP = {"PXD006452" : SNAKEMAKE_DIR + "/config/comet_high_low.params"}

rule comet_search:
    input:
        mzml = "data/{dataset}/{basename}.mzML",
        parameter_file = lambda wildcards: COMET_PARAM_MAP[wildcards.dataset],
        ref = SNAKEMAKE_DIR + "/config/sp_iso_HUMAN_4.9.2015_UP000005640.fasta"
    output:
        log = "search/{dataset}/{basename}.comet.log.txt",
        pep_xml = "search/{dataset}/{basename}.comet.target.pep.xml"
    params:
        fileroot = "{basename}",
        output_dir = "search/{dataset}/"
    conda:
        SNAKEMAKE_DIR + "/envs/crux.yaml"
    group:
        "database_search"
    shell:
        """
        crux comet --parameter-file {input.parameter_file} \
                   --fileroot {params.fileroot} \
                   --output-dir {params.output_dir} \
                   --overwrite T \
                   --output_pepxmlfile 1 \
                   {input.mzml} {input.ref}
        """

