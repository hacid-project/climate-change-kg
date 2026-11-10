# Validation of the consolidated KG with the SHACL shapes of shapes/ (see
# shapes/README.md), with the Jena command-line tools (shacl, arq, riot).
#
# The shapes are validated against the union of the named graphs of the KG,
# without the graph of its metadata (shapes/queries/data.rq). The report
# (kg/validation/report.ttl) is summarised by severity, shape and message
# (summary.tsv to read, summary.json for jq), and the rule validate fails if
# there are results of the severities of config.yaml (validate.fail_on). The
# report and its summary are written in any case: the metadata of the KG has
# the numbers of the results (rule metadata_quality).
#

SHAPES = sorted(glob.glob("shapes/*.ttl"))

# Threads of the rules that must run alone, as they open the TDB2 dataset
# (which only one process at a time can open) or run a JVM with the whole KG in
# memory: more than the cores, so that they take them all
ALL_CORES = 1024


rule validate:
    input:
        "kg/validation/passed",


# All the shapes in one graph (and the check of their syntax)
rule validate_shapes:
    input:
        SHAPES,
    output:
        "kg/validation/shapes.ttl",
    log:
        "logs/validate/shapes.log",
    shell:
        "riot --formatted=ttl {input:q} > {output:q} 2> {log:q}"


# The data graph: the union of the named graphs of the KG
rule validate_data:
    input:
        updated="kg/updates.done",
        query="shapes/queries/data.rq",
    output:
        temp("kg/validation/data.ttl"),
    params:
        location=config["consolidate"]["location"],
        jvm_args=config["consolidate"]["jvm_args"],
    threads: ALL_CORES
    log:
        "logs/validate/data.log",
    shell:
        "JVM_ARGS={params.jvm_args:q} tdb2.tdbquery --loc {params.location:q} --query {input.query:q}"
        " > {output:q} 2> {log:q}"


rule validate_shacl:
    input:
        shapes="kg/validation/shapes.ttl",
        data="kg/validation/data.ttl",
    output:
        "kg/validation/report.ttl",
    params:
        jvm_args=config["consolidate"]["jvm_args"],
    threads: ALL_CORES
    log:
        "logs/validate/shacl.log",
    shell:
        "JVM_ARGS={params.jvm_args:q} shacl validate --shapes {input.shapes:q} --data {input.data:q}"
        " > {output:q} 2> {log:q}"


# The results by severity, shape and message, as SPARQL results (JSON) and as
# a table
rule validate_summary:
    input:
        report="kg/validation/report.ttl",
        query="shapes/queries/summary.rq",
    output:
        json="kg/validation/summary.json",
        tsv="kg/validation/summary.tsv",
    log:
        "logs/validate/summary.log",
    shell:
        "arq --data {input.report:q} --query {input.query:q} --results=json > {output.json:q} 2> {log:q} &&"
        " jq -r '.head.vars as $vars | $vars, (.results.bindings[] | [.[$vars[]].value]) | @tsv'"
        " {output.json:q} > {output.tsv:q} 2>> {log:q}"


# Fails, listing them, if there are results of the severities of
# validate.fail_on
rule validate_check:
    input:
        "kg/validation/summary.json",
    output:
        touch("kg/validation/passed"),
    params:
        fail_on=json.dumps(config["validate"]["fail_on"]),
    shell:
        "jq -r --argjson fail_on {params.fail_on:q}"
        " '[.results.bindings[] | select(.severity.value | sub(\".*#\"; \"\") | IN($fail_on[])) |"
        " \"\\(.results.value)\\t\\(.shape.value)\\t\\(.message.value)\"] |"
        " if length > 0 then"
        " ([\"The KG does not conform to its shapes (kg/validation/summary.tsv):\"] + . | join(\"\\n\") + \"\\n\" | halt_error)"
        " else empty end' {input:q}"
