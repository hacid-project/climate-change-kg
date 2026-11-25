# Metadata of the KG, describing it as a dataset with DCAT, VoID, the SPARQL
# service description, PROV-O and DQV (see metadata/kg.ttl): the description
# written by hand is completed with its creators (metadata/record.yaml), the
# statistics of the KG and of its named graphs, the provenance of the build (and
# of the release being made, if any) and the results of the validation, checked
# with its own shapes (metadata/shapes.ttl), written to kg/export/void.ttl and
# loaded in the KG as the named graph of config.yaml (metadata.graph), which
# replaces that of a previous build.
#
# The rules opening the TDB2 dataset run alone (ALL_CORES, rules/validate.smk).


rule metadata:
    input:
        "kg/metadata.done",


# VoID statistics of the KG and of its named graphs
rule metadata_statistics:
    input:
        updated="kg/updates.done",
        query="metadata/statistics.rq",
    output:
        "kg/metadata/statistics.ttl",
    params:
        location=config["consolidate"]["location"],
        jvm_args=config["consolidate"]["jvm_args"],
    threads: ALL_CORES
    log:
        "logs/metadata/statistics.log",
    shell:
        "JVM_ARGS={params.jvm_args:q} tdb2.tdbquery --loc {params.location:q} --query {input.query:q}"
        " > {output:q} 2> {log:q}"


# The creators of the KG, from metadata/record.yaml (shared with its record
# on Zenodo)
rule metadata_creators:
    input:
        record="metadata/record.yaml",
        mapping="metadata/creators.jq",
    output:
        "kg/metadata/creators.jsonld",
    log:
        "logs/metadata/creators.log",
    shell:
        "yq -f {input.mapping:q} {input.record:q} > {output:q} 2> {log:q}"


# The release being made, if any (snakemake release --config version=X.Y.Z):
# its version, DOI and previous release, known once its draft is created on
# Zenodo and its commit made (rules/release.smk)
def metadata_release(wildcards):
    if config.get("version"):
        return [f"kg/release/{config['version']}/commit.done"]
    return []


# The build (date, commit of the workflow), the versions of the sources given
# by the configuration and, for a release, the release
rule metadata_provenance:
    input:
        updated="kg/updates.done",
        mapping="metadata/provenance.jq",
        release=metadata_release,
    output:
        "kg/metadata/provenance.jsonld",
    params:
        config=json.dumps(config),
        release=lambda wildcards, input: (
            f"--argjson release \"$(jq -c .release {os.path.dirname(input.release[0])}/commit.json)\""
            if input.release
            else ""
        ),
    log:
        "logs/metadata/provenance.log",
    shell:
        "jq -n --argjson config {params.config:q} --arg commit $(git rev-parse HEAD)"
        " --arg date $(date -u +%Y-%m-%dT%H:%M:%SZ) {params.release} -f {input.mapping:q} > {output:q} 2> {log:q}"


# The numbers of results of the validation
rule metadata_quality:
    input:
        summary="kg/validation/summary.json",
        mapping="metadata/quality.jq",
    output:
        "kg/metadata/quality.jsonld",
    log:
        "logs/metadata/quality.log",
    shell:
        "jq -f {input.mapping:q} {input.summary:q} > {output:q} 2> {log:q}"


# The whole description, in one file
rule metadata_void:
    input:
        "metadata/kg.ttl",
        "kg/metadata/creators.jsonld",
        "kg/metadata/statistics.ttl",
        "kg/metadata/provenance.jsonld",
        "kg/metadata/quality.jsonld",
    output:
        "kg/export/void.ttl",
    log:
        "logs/metadata/void.log",
    shell:
        "riot --formatted=ttl {input:q} > {output:q} 2> {log:q}"


# Key figures of the KG (models, simulations, datasets, variables, indices,
# ...), quoted by the website, the release notes and the record on Zenodo:
# not part of the description
rule metadata_figures:
    input:
        updated="kg/updates.done",
        query="metadata/figures.rq",
    output:
        "kg/metadata/figures.json",
    params:
        location=config["consolidate"]["location"],
        jvm_args=config["consolidate"]["jvm_args"],
    threads: ALL_CORES
    log:
        "logs/metadata/figures.log",
    shell:
        "JVM_ARGS={params.jvm_args:q} tdb2.tdbquery --loc {params.location:q} --set tdb:unionDefaultGraph=true"
        " --query {input.query:q} --results=json > {output:q} 2> {log:q}"


# Check of the description with its shapes: fails if it does not conform
rule metadata_validate:
    input:
        shapes="metadata/shapes.ttl",
        data="kg/export/void.ttl",
    output:
        "kg/metadata/report.ttl",
    log:
        "logs/metadata/validate.log",
    shell:
        "shacl validate --shapes {input.shapes:q} --data {input.data:q} > {output:q} 2> {log:q};"
        " grep -q 'sh:conforms *true' {output:q} ||"
        " {{ echo 'The metadata does not conform to metadata/shapes.ttl:'; cat {output:q}; mv {output:q} {output:q}.failed; exit 1; }} >&2"


rule metadata_load:
    input:
        void="kg/export/void.ttl",
        report="kg/metadata/report.ttl",
    output:
        touch("kg/metadata.done"),
    params:
        location=config["consolidate"]["location"],
        jvm_args=config["consolidate"]["jvm_args"],
        graph=config["metadata"]["graph"],
    threads: ALL_CORES
    log:
        "logs/metadata/load.log",
    shell:
        "export JVM_ARGS={params.jvm_args:q};"
        " (tdb2.tdbupdate --loc {params.location:q} 'DROP SILENT GRAPH <{params.graph}>' &&"
        " tdb2.tdbloader --loc {params.location:q} --graph={params.graph:q} {input.void:q}) > {log:q} 2>&1"
