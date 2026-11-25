# Climate Change Knowledge Graph (CCKG): workflow

The [Climate Change Knowledge Graph](https://w3id.org/climate-change-kg) describes, as linked data, the climate
information used by climate services: climate variables and indices, hazards, emissions scenarios, climate models,
simulations and projection datasets (CMIP5, CORDEX-CMIP5, UKCP18). This repository is the workflow that builds it from
its sources, validates it and releases it. The releases are archived on Zenodo
([10.5281/zenodo.24305088](https://doi.org/10.5281/zenodo.24305088)) and served at
<https://w3id.org/climate-change-kg/sparql>. It was first developed in the European project
[HACID](https://www.hacid-project.eu/).

## How the pipeline is organised

```
sources ──▶ mapping ──▶ consolidation ──▶ validation ──▶ metadata ──▶ export ──▶ release
(pinned)    (jq, per    (Jena TDB2 +      (SHACL         (DCAT, VoID,  (kg.nq.gz,  (git tag, GitHub,
            source)     SPARQL updates)   shapes)        PROV, DQV)    void.ttl)   Zenodo, website)
```

- **Sources.** Every source is taken at a fixed version given in `config/config.yaml`: git commits of public
  repositories, versions of tables, Zenodo snapshots of the dataset metadata. Some content is curated in this
  repository (`data-sources/*/data`, `data-sources/*.ttl`).
- **Mapping.** Each source has a folder, `data-sources/<source>/`, with its mapping to RDF (`mapping/`, jq programs),
  its downloaded data (`data/`), its output (`rdf/`, JSON-LD) and the decisions taken on its issues (`DECISIONS.md`).
- **Consolidation.** The outputs and the hand-written files, listed with their named graphs in `graph_names.csv`, are
  loaded into an Apache Jena TDB2 dataset (`kg/`), and the SPARQL updates of `consolidation/` are applied to it.
- **Validation.** The KG is checked with the SHACL shapes of `shapes/`.
- **Metadata.** The KG is described as a dataset (`metadata/`): creators, statistics, provenance (the build and the
  version of every source), results of the validation, key figures.
- **Export.** The KG is dumped as `kg/export/kg.nq.gz` with its description `kg/export/void.ttl`.
- **Release.** A version of the KG is published on Zenodo, and the repository, its tag, the GitHub release, the
  record of the workflow on Zenodo and the website are made coherent with it.

All the steps are rules of one [Snakemake](https://snakemake.github.io/) workflow (`workflow/Snakefile`,
`workflow/rules/`). How each step works is described in [`doc/pipeline.md`](doc/pipeline.md).

| Path | Content |
|:--|:--|
| `config/config.yaml` | versions of the sources, options of the steps, release settings |
| `data-sources/` | one folder per source: mapping, decisions, (downloaded) data, (generated) RDF |
| `graph_names.csv` | the files of each named graph of the KG |
| `consolidation/`, `consolidation_updates.csv` | the SPARQL updates applied after the load, in order |
| `shapes/` | the SHACL shapes of the KG ([`shapes/README.md`](shapes/README.md)) |
| `metadata/` | the description of the KG: hand-written parts (`kg.ttl`, `record.yaml`) and the queries and mappings completing it |
| `publication/` | release notes, templates of the releases, w3id redirects |
| `website/` | the documentation website (GitHub Pages), with the facts of the releases in `website/_data/releases.json` |
| `deployment/` | the setup of the server of the SPARQL endpoint and of the linked data, keng.istc.cnr.it ([`deployment/README.md`](deployment/README.md)) |
| `example-queries/`, `checkup-queries/` | SPARQL queries: examples, and checks of the KG |
| `kg/`, `logs/` | outputs of the workflow (not tracked) |

## Requirements

To **build** the KG:

| Requirement | Version | Check | Notes |
|:--|:--|:--|:--|
| git | any recent | `git --version` | also used to fetch the pinned sources |
| Python | 3.11 or later | `python3 --version` | Snakemake 9 needs 3.11 |
| The Python packages of `workflow/requirements.txt` | as listed | `snakemake --version` | Snakemake and its git and Zenodo storage plugins, `yq` (gives `xq` and `yq`), `csvkit` (gives `csvjson`), `xlrd`, and, for the releases, `requests`, `pyyaml`, `rdflib`, `markdown` |
| jq | 1.8 or later | `jq --version` | the UKCP18 mapping uses syntax of jq 1.8 |
| curl, gzip, tar | any | | |
| Java | 21 or later | `java -version` | required by Apache Jena 6 |
| Apache Jena command-line tools | 6.2.0 | `riot --version` | `riot`, `arq`, `shacl`, `tdb2.tdbloader`, `tdb2.tdbupdate`, `tdb2.tdbquery`, `tdb2.tdbdump` on the `PATH` (the `bin/` folder of the [binary distribution](https://jena.apache.org/download/)) |
| Memory | 16 GB for the JVM | | `consolidate.jvm_args` (`-Xmx16G`): the JSON-LD parser of Jena reads a whole document in memory |
| Disk | several GB | | the two TDB2 datasets (as loaded, and consolidated) take about 2.2 GB each; the sources and their RDF take more |
| Network | | | GitHub (pinned repositories), Zenodo (snapshots of the dataset metadata), cfconventions.org (CF standard names) |

Optional, to inspect the KG locally: Apache Jena Fuseki (`fuseki-server` on the `PATH`).

To **release** a version, also:

| Requirement | How to get it | Check |
|:--|:--|:--|
| A Zenodo personal access token with the scopes `deposit:write` and `deposit:actions`, of an account that can edit the record of the KG ([10.5281/zenodo.24305088](https://doi.org/10.5281/zenodo.24305088)) | zenodo.org > Account > Applications > Personal access tokens | `export ZENODO_TOKEN=...` (the release checks it) |
| The GitHub CLI, authenticated with the right to push to `hacid-project/climate-change-kg` | [cli.github.com](https://cli.github.com/), then `gh auth login` | `gh auth status` |
| The Zenodo GitHub integration turned on for `hacid-project/climate-change-kg` | zenodo.org > Account > GitHub (needs admin rights on the repository) | the workflow record [10.5281/zenodo.24304389](https://doi.org/10.5281/zenodo.24304389) gets a version for each GitHub release |
| A git identity | `git config user.name` / `user.email` | the release makes a commit and a tag |

## Setup (once)

```bash
git clone https://github.com/hacid-project/climate-change-kg.git
```

```bash
cd climate-change-kg
```

```bash
python3 -m venv .venv
```

Activate the environment (in every new terminal):

```bash
source .venv/bin/activate
```

```bash
pip install -r workflow/requirements.txt
```

Then install jq, Java and Jena with your package manager or from their sites, put the Jena `bin/` folder on the
`PATH`, and check each command of the table above.

All the commands below are run from the root of the repository, with the virtual environment active. `--cores 4` is
the number of jobs run in parallel; the steps that open the TDB2 dataset run alone anyway.

## Analyze the sources

```bash
snakemake --cores 4 sources_analysis
```

It analyses the sources without changing the KG, to review the mappings and the decisions of the `DECISIONS.md` files:

| Output | What it tells |
|:--|:--|
| `data-sources/cmor-tables/analysis/` | how the variable definitions evolve across all the editions of the CMOR tables of `config/config.yaml` (`cmor_tables.editions`): additions, deletions, changes, names reused (see its README) |
| `data-sources/ukcp18/analysis/unmapped-variables.json.gz` | the UKCP18 datasets whose variable is not a variable of the KG |
| `data-sources/ukcp18/analysis/variables-check.json` | the local UKCP18 variables checked against the datasets |
| `data-sources/cordex-cmip5/analysis/variables-check.json`, `.csv` | the variables of the CORDEX-CMIP5 datasets against the CORDEX standard output and the variables of the KG |

To look at a built KG, serve it read-only with Fuseki at `http://localhost:3030/kg` (SPARQL endpoint `/kg/sparql`,
union of the named graphs as default graph, no inference), not while the workflow is writing it:

```bash
./serve_kg.sh
```

The queries of `checkup-queries/` (dangling IRIs, missing types, ...) and of `example-queries/` can be run there.

## Build and validate the KG

One command builds the whole KG from scratch, or rebuilds what a change affects:

```bash
snakemake --cores 4
```

(The default target is `build`.) It fetches the sources at their pinned versions, maps them, consolidates them,
validates the KG with its shapes, describes it and exports it. Snakemake reruns only the steps whose inputs changed: a
change in a mapping reruns that mapping and the steps after it. The first build takes a while (the UKCP18 and CORDEX
mappings are the longest); the sources stay cached in `.snakemake/storage/` and `data-sources/*/data`.

It **fails** if the KG does not conform to its shapes (results of the severities of `validate.fail_on`, by default
violations), listing them; warnings and informative results are only reported. It also fails if the metadata does not
conform to `metadata/shapes.ttl` (e.g. a named graph without a description in `metadata/kg.ttl`).

The outputs:

| File | Content |
|:--|:--|
| `kg/export/kg.nq.gz` | the KG, all its named graphs, as gzipped N-Quads (also loaded in `kg/tdb2`) |
| `kg/export/void.ttl` | its description: creators, statistics, provenance, validation results |
| `kg/validation/summary.tsv` | the results of the validation by severity, shape and message (`report.ttl` has them all; how to read it: [`shapes/README.md`](shapes/README.md)) |
| `kg/metadata/figures.json` | the key figures: models, simulations, datasets, variables, indices, ... |
| `logs/` | the log of every step |

Parts of the build can be run on their own: `mapping` (all the mappings), a single source (`ontologies`, `gwls`,
`cf_standard_names`, `cmor_tables`, `cmip5_cvs`, `cmip5`, `cordex_domains`, `cordex_cmip5_cvs`, `cordex_cmip5`,
`ukcp18`, `climdex`, `mohc_cvs`), `consolidate` (load, updates, metadata, export), `validate`, `metadata`. For example:

```bash
snakemake --cores 4 cmor_tables
```

To force a step to run again (e.g. a source pinned to a branch that moved), add `--forcerun <rule>`; to see what
would run, add `-n`.

What to edit for common changes:

| Change | Edit | Then |
|:--|:--|:--|
| A mapping, or the curated data of a source | `data-sources/<source>/mapping/`, `data/` (and its `DECISIONS.md`) | build |
| A newer version of a source | `config/config.yaml` | build; update the hand-written figures of the source in `website/sources.md` |
| The ontologies | their commit in `config/config.yaml` (`ontologies.version`) | build |
| A consolidation update | `consolidation/`, listed in `consolidation_updates.csv` | build |
| The shapes | `shapes/*.ttl` | build |
| A new named graph | `graph_names.csv`, and its description in `metadata/kg.ttl` | build |
| The creators, title or keywords | `metadata/record.yaml` (shared with Zenodo) | build |
| Anything worth a release | a line in the section *Unreleased* of `CHANGELOG.md` | |

## Release a new version

A release makes everything coherent with a new version of the KG:

- **the repository:** a release commit, tagged `vX.Y.Z`, with `CHANGELOG.md` (the changes moved to their version),
  `CITATION.cff` (version and date), the release notes `publication/releases/vX.Y.Z.md`, and the data of the website
  `website/_data/releases.json` (versions, DOIs, figures, versions of the sources), from which the website shows the
  releases and the current figures;
- **GitHub:** the release commit and the tag pushed, and a GitHub release with the notes;
- **the record of the workflow on Zenodo:** a new version, archived from the GitHub release by the Zenodo GitHub
  integration;
- **the record of the KG on Zenodo:** a new version with the dump and its description, and the metadata of
  `metadata/record.yaml` (creators, keywords, licence, funding), the version, a description generated from the release
  (`publication/templates/zenodo-description.md`), and the related identifiers: the workflow version
  (`isCompiledBy`), the snapshots of the sources (`isDerivedFrom`), the ontologies (`requires`), the website
  (`isDocumentedBy`);
- **the KG itself:** its description (`void.ttl`, also in the dump) says that it is this release, with its DOI, its
  previous release and the commit of the tag that built it.

### Choose the version

Versions follow semantic versioning on what queries rely on: the IRIs, the named graphs and the SHACL shapes.

- **Major** (`2.0.0`): a change that breaks queries: IRIs removed or renamed (without a deprecated equivalent),
  named graphs changed, shapes changed so that queries break (a property removed, a range changed), an incompatible
  version of the ontologies.
- **Minor** (`1.1.0`): new content or structure: new sources, new kinds of entities or properties, a newer snapshot of a
  source.
- **Patch** (`1.0.1`): corrections of values or labels, fixes of the metadata, no change of structure.

### Step by step

1. **Describe the changes.** Make sure the section *Unreleased* of `CHANGELOG.md` lists what changed since the last
   release (the release refuses to start if it is empty). If a source changed, update its hand-written figures in
   `website/sources.md` (the versions and the numbers of datasets there are filled in by the release).
2. **Get the repository ready.** Merge everything into `main`, then `git checkout main && git pull`. The working tree
   must be clean and `main` equal to `origin/main`.
3. **Set the credentials** (see [Requirements](#requirements)):

   ```bash
   export ZENODO_TOKEN=<your Zenodo token>
   ```

4. **Preview (recommended).** Everything except what is public:

   ```bash
   snakemake --cores 4 release_preview --config version=X.Y.Z
   ```

   It builds and validates the KG, checks the preconditions, creates the draft of the new version on Zenodo (with its
   DOI reserved), makes the release commit and the tag **locally**, rebuilds the description of the KG with the
   release, and uploads the files and the metadata to the draft. Review the draft at the URL printed at the end
   (`[release] The draft is ready to review: ...`), the release commit (`git show`) and the notes
   (`publication/releases/vX.Y.Z.md`). To give up, see [If something goes wrong](#if-something-goes-wrong).
5. **Release:**

   ```bash
   snakemake --cores 4 release --config version=X.Y.Z
   ```

   It does what the preview does (or reuses it), then pushes the release commit and the tag, makes the GitHub release,
   waits for the Zenodo GitHub integration to archive it (up to `release.workflow_doi_timeout` minutes), and publishes
   the version of the KG on Zenodo with the DOI of that workflow version. It ends with
   `[release] Published the Climate Change Knowledge Graph X.Y.Z: https://doi.org/...`.
6. **After the release.** The website is redeployed automatically by GitHub Actions (the release commit changes
   `website/`). The SPARQL endpoint and the linked data front end load the new version from Zenodo by themselves,
   within an hour ([`deployment/`](deployment/README.md)). Your local KG still describes itself as the release; the next
   `snakemake --cores 4` describes it again as a build of its commit.

The steps of the release, in order (`workflow/rules/release.smk`, `workflow/scripts/release.py`):

| Rule | What it does | Public? |
|:--|:--|:--|
| `build` | the KG built and validated | no |
| `release_check` | version newer than the latest release on Zenodo and than the tags; clean working tree, on `main`, equal to `origin/main`; changes in `CHANGELOG.md`; Zenodo token and GitHub CLI working | no |
| `release_draft` | a draft of the new version of the KG record on Zenodo, with its DOI reserved | no (a draft is private) |
| `release_commit` | the release commit and the tag `vX.Y.Z`, local | no |
| `metadata_*`, `consolidate_export` | the description of the KG rebuilt at the release commit, with the version and the DOI, and the KG exported | no |
| `release_upload` | the files and the metadata uploaded to the draft | no |
| `release_github` | the commit and the tag pushed; the GitHub release; the DOI of the workflow version | **yes** |
| `release_publish` | the version of the KG published on Zenodo (cannot be undone) | **yes** |

Each step records its state in `kg/release/X.Y.Z/`.

### If something goes wrong

- **A step failed** (network error, Zenodo unavailable, timeout of the GitHub integration): fix the cause and **run the
  same command again**. The release resumes from the step that failed, reusing what exists (the draft, the commit,
  the uploaded files).
- **To give up before anything is public** (after a preview, or after a failure before `release_github`):

  ```bash
  snakemake --cores 1 release_discard --config version=X.Y.Z
  ```

  It deletes the draft on Zenodo, the local tag and the release commit, and the state of the release. Then run
  `snakemake --cores 4` so that the KG describes itself as a build again.
- **`main` is protected** and the push of the release commit is refused: merge the release commit into `main` through
  a pull request (with a merge commit, so that the tagged commit stays as it is), then run the release command again.
- **The Zenodo GitHub integration is off**, so no workflow version appears: turn it on (zenodo.org > Account >
  GitHub), then delete and recreate the GitHub release for the tag (the integration archives releases made while it is
  on), and run the release command again.
- **Rehearse a whole release** on [sandbox.zenodo.org](https://sandbox.zenodo.org), a separate test site (its own
  account and token), without pushing anything, with a pre-release version:

  ```bash
  export ZENODO_TOKEN=<your token of sandbox.zenodo.org>
  ```

  ```bash
  snakemake --cores 4 release --configfile config/release-sandbox.yaml --config version=X.Y.Z-rc1
  ```

  Then undo the local commit and tag:

  ```bash
  snakemake --cores 1 release_discard --configfile config/release-sandbox.yaml --config version=X.Y.Z-rc1
  ```

### What the release reads

| File | Role |
|:--|:--|
| `CHANGELOG.md` | the changes (section *Unreleased*) |
| `metadata/record.yaml` | title, creators, keywords, licence, funding, communities, extra related identifiers of the Zenodo record; the creators also go in the KG |
| `publication/templates/release-notes.md` | the template of the release notes (and of the GitHub release) |
| `publication/templates/zenodo-description.md` | the template of the description on Zenodo |
| `config/config.yaml`, section `release` | Zenodo site and records, GitHub repository, branch and remote, what to push |
| `kg/metadata/statistics.ttl`, `figures.json`, `kg/validation/summary.json`, `shapes.ttl` | the facts quoted (size, named graphs, figures, validation) |

## Configuration

`config/config.yaml` holds, by section: the editions of the CMOR tables to analyse (`cmor_tables`), the versions of
the sources (`cmip5`, `cordex_cmip5`, `cf_standard_names`, `cordex_domains`, `cmip5_cvs`, `cordex_cmip5_cvs`,
`ontologies`, `ukcp18`; `config/cmor-tables-eras.json` gives the repositories of the CMOR tables), the locations and the
memory of the TDB2 datasets (`consolidate`), the severities that fail the validation (`validate`), the named graph and
the public locations of the KG written in its metadata (`metadata`), and the release settings (`release`). Each option
is commented in the file.

## Further documentation

- [`doc/pipeline.md`](doc/pipeline.md): how each step and each source mapping works.
- [`doc/conventions.md`](doc/conventions.md): the conventions of labels, comments and IRIs.
- [`shapes/README.md`](shapes/README.md): the shapes, their severities and how to read the validation report.
- [`deployment/README.md`](deployment/README.md): how the KG is served at keng.istc.cnr.it (SPARQL endpoint, linked
  data), and how to set up that server.
- `data-sources/<source>/DECISIONS.md`: the decisions taken on each source.
- [`CHANGELOG.md`](CHANGELOG.md) and [`publication/releases/`](publication/releases/): the releases.
- The website, <https://w3id.org/climate-change-kg>: the content, the data model, the competency questions and the
  example queries.

## Licence

The code is released under the MIT licence (`LICENSE`), the KG under CC BY 4.0.
