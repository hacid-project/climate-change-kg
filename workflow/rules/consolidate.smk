# Consolidation of the KG: the outputs of the mappings (rule mapping) and the
# files written by hand, as listed in graph_names.csv, are loaded into a TDB2
# dataset (config.yaml, consolidate.loaded_location, kg/tdb2-loaded, not
# tracked), the updates of consolidation/ (listed in consolidation_updates.csv)
# are applied to a copy of it (consolidate.location, kg/tdb2), its metadata is
# added (rules/metadata.smk, with the results of its
# validation, rules/validate.smk), and it is exported as N-Quads
# (kg/export/kg.nq.gz). It uses the Jena command-line tools (tdb2.tdbloader,
# tdb2.tdbupdate, tdb2.tdbdump). The updates see the union of the named graphs
# as default graph (tdb:unionDefaultGraph), as in the Fuseki configuration
# (fuseki-conf.ttl).
#
# The loaded dataset is only read after the load: the updates always start
# from a new copy of it, so that a change in the updates reruns them without
# loading the RDF files again (the costly step), and never on a dataset already
# updated. The consolidated dataset is modified in place by the updates and by
# the load of the metadata: the steps record their completion in kg/
# (load.json, updates.done, metadata.done), so that a change in the inputs of a
# step reruns it and the following ones.

# The files written by hand listed in graph_names.csv: those tracked in git
# (the others are outputs of the mappings, inputs through rule mapping)
CONSOLIDATE_STATIC_FILES = sorted(
    shell(
        "git ls-files -- "
        + " ".join(
            f"'{row['path']}'"
            for row in csv.DictReader(open("graph_names.csv", newline=""))
            if row["skip"].strip() != "y"
        ),
        read=True,
    ).split()
)

# The updates of consolidation_updates.csv, in their order
CONSOLIDATE_UPDATES = [
    row["path"]
    for row in csv.DictReader(open("consolidation_updates.csv", newline=""))
    if row["skip"].strip() != "y"
]


rule consolidate:
    input:
        "kg/export/kg.nq.gz",


rule consolidate_load:
    input:
        rules.mapping.input,
        CONSOLIDATE_STATIC_FILES,
        graph_names="graph_names.csv",
    output:
        report="kg/load.json",
    params:
        location=config["consolidate"]["loaded_location"],
        jvm_args=config["consolidate"]["jvm_args"],
    log:
        "logs/consolidate/load.log",
    script:
        "../scripts/consolidate_load.py"


# The updates, in their order, on a new copy of the loaded dataset
rule consolidate_updates:
    input:
        loaded="kg/load.json",
        updates_list="consolidation_updates.csv",
        updates=CONSOLIDATE_UPDATES,
    output:
        touch("kg/updates.done"),
    params:
        loaded_location=config["consolidate"]["loaded_location"],
        location=config["consolidate"]["location"],
        jvm_args=config["consolidate"]["jvm_args"],
    log:
        "logs/consolidate/updates.log",
    shell:
        "export JVM_ARGS={params.jvm_args:q};"
        " rm -rf {params.location:q} && cp -R {params.loaded_location:q} {params.location:q} &&"
        " for update in {input.updates:q}; do"
        " echo \"Running $update\";"
        " tdb2.tdbupdate --loc {params.location:q} --set tdb:unionDefaultGraph=true --update \"$update\" || exit 1;"
        " done > {log:q} 2>&1"


rule consolidate_export:
    input:
        described="kg/metadata.done",
    output:
        "kg/export/kg.nq.gz",
    params:
        location=config["consolidate"]["location"],
        jvm_args=config["consolidate"]["jvm_args"],
    log:
        "logs/consolidate/export.log",
    shell:
        "export JVM_ARGS={params.jvm_args:q};"
        " (tdb2.tdbdump --loc {params.location:q} | gzip > {output:q}) 2> {log:q}"
