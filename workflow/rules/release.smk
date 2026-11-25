# Release of the KG (workflow/scripts/release.py): one command,
#
#   snakemake --cores 4 release --config version=X.Y.Z
#
# makes the repository, the record of the KG on Zenodo and the record of the
# workflow on Zenodo coherent with a new version. The build is brought up to
# date and validated first (rule build); then, in order:
#
#   release_check    the preconditions (version, clean and pushed repository,
#                    changelog, Zenodo token, GitHub CLI)
#   release_draft    a draft of the new version of the record of the KG on
#                    Zenodo, with its DOI reserved
#   release_commit   the release commit (CHANGELOG.md, CITATION.cff, the notes
#                    publication/releases/vX.Y.Z.md, website/_data/releases.json)
#                    and its tag vX.Y.Z, local only
#   (the metadata of the KG is rebuilt at the release commit, with the version
#   and the DOI of the release, and the KG is exported again)
#   release_upload   the dump and its description uploaded to the draft, with
#                    the metadata of the version
#   release_github   the commit and the tag pushed, the GitHub release made,
#                    and the DOI of the workflow waited for (Zenodo GitHub
#                    integration)
#   release_publish  the version published on Zenodo
#
# Each step records its result in kg/release/X.Y.Z/<step>.json (its state,
# read by the following steps) and marks its completion with <step>.done (the
# output of its rule). The steps are idempotent given their state, so a release
# interrupted by an error resumes from where it stopped when the command is run
# again, and a step run again reuses what exists (e.g. the draft on Zenodo).
# release_preview stops before anything public (the draft on Zenodo can be
# reviewed, and the commit and the tag are local); release_discard undoes a
# release that is not public yet. With --configfile config/release-sandbox.yaml
# the whole release is rehearsed on sandbox.zenodo.org, without pushing.

RELEASE_VERSION = config.get("version")
RELEASE_STATE = f"kg/release/{RELEASE_VERSION}"

# The facts of the build quoted by the release (notes, Zenodo, website)
RELEASE_FACTS = {
    "passed": "kg/validation/passed",
    "summary": "kg/validation/summary.json",
    "shapes": "kg/validation/shapes.ttl",
    "statistics": "kg/metadata/statistics.ttl",
    "figures": "kg/metadata/figures.json",
}


def release_command(step):
    return (
        f"python3 workflow/scripts/release.py {step} --version {{params.version:q}} --state {{params.state:q}}"
        " --config {input.config:q} --statistics {input.statistics:q} --figures {input.figures:q}"
        " --validation {input.summary:q} --shapes {input.shapes:q}"
        f" --cmor-previous-editions {len(MIP_EDITIONS['previous'])}"
    )


if not RELEASE_VERSION:

    rule release:
        message:
            "Give the version of the release: snakemake --cores 4 release --config version=X.Y.Z"
        shell:
            "exit 1"

    rule release_preview:
        message:
            "Give the version of the release: snakemake --cores 4 release_preview --config version=X.Y.Z"
        shell:
            "exit 1"

    rule release_discard:
        message:
            "Give the version of the release: snakemake --cores 1 release_discard --config version=X.Y.Z"
        shell:
            "exit 1"

else:

    rule release:
        input:
            f"{RELEASE_STATE}/publish.done",

    # Everything but what is public: the draft on Zenodo, the local commit and tag
    rule release_preview:
        input:
            f"{RELEASE_STATE}/upload.done",

    # The configuration of the workflow, as read by the release script
    rule release_config:
        output:
            f"{RELEASE_STATE}/config.json",
        params:
            config=json.dumps(config, indent=2),
        run:
            with open(output[0], "w") as f:
                f.write(params.config)

    rule release_check:
        input:
            config=f"{RELEASE_STATE}/config.json",
            **RELEASE_FACTS,
        output:
            f"{RELEASE_STATE}/checked.done",
        params:
            version=RELEASE_VERSION,
            state=RELEASE_STATE,
        shell:
            release_command("check") + " && touch {output:q}"

    rule release_draft:
        input:
            f"{RELEASE_STATE}/checked.done",
            config=f"{RELEASE_STATE}/config.json",
            **RELEASE_FACTS,
        output:
            f"{RELEASE_STATE}/draft.done",
        params:
            version=RELEASE_VERSION,
            state=RELEASE_STATE,
        shell:
            release_command("draft") + " && touch {output:q}"

    rule release_commit:
        input:
            f"{RELEASE_STATE}/draft.done",
            config=f"{RELEASE_STATE}/config.json",
            **RELEASE_FACTS,
        output:
            f"{RELEASE_STATE}/commit.done",
        params:
            version=RELEASE_VERSION,
            state=RELEASE_STATE,
        shell:
            release_command("commit") + " && touch {output:q}"

    # The KG exported again after the release commit: its metadata (rule
    # metadata_provenance) has the version and the DOI of the release
    rule release_upload:
        input:
            f"{RELEASE_STATE}/commit.done",
            "kg/metadata/report.ttl",
            dump="kg/export/kg.nq.gz",
            void="kg/export/void.ttl",
            config=f"{RELEASE_STATE}/config.json",
            **RELEASE_FACTS,
        output:
            f"{RELEASE_STATE}/upload.done",
        params:
            version=RELEASE_VERSION,
            state=RELEASE_STATE,
        shell:
            release_command("upload") + " --dump {input.dump:q} --void {input.void:q} && touch {output:q}"

    rule release_github:
        input:
            f"{RELEASE_STATE}/upload.done",
            config=f"{RELEASE_STATE}/config.json",
            **RELEASE_FACTS,
        output:
            f"{RELEASE_STATE}/github.done",
        params:
            version=RELEASE_VERSION,
            state=RELEASE_STATE,
        shell:
            release_command("github") + " && touch {output:q}"

    rule release_publish:
        input:
            f"{RELEASE_STATE}/github.done",
            config=f"{RELEASE_STATE}/config.json",
            **RELEASE_FACTS,
        output:
            f"{RELEASE_STATE}/publish.done",
        params:
            version=RELEASE_VERSION,
            state=RELEASE_STATE,
        shell:
            release_command("publish") + " && touch {output:q}"

    # Not depending on the build: only undoes what the release did
    rule release_discard:
        input:
            config=f"{RELEASE_STATE}/config.json",
        params:
            version=RELEASE_VERSION,
            state=RELEASE_STATE,
        shell:
            "python3 workflow/scripts/release.py discard --version {params.version:q} --state {params.state:q}"
            " --config {input.config:q} && rm -f {params.state:q}/*.done"
