# Climate Change Knowledge Graph $version

Released on $date: version $version of the workflow and of the Climate Change Knowledge Graph (CCKG), archived on
Zenodo at $doi_link (all the releases: $concept_doi_link). Previous release: $previous_link.

## Changes

$changes

## The knowledge graph

- **Size:** $triples triples (without inferred ones), in $named_graphs named graphs, plus a named graph with the
  metadata of the KG.
- **Content:** $simulations simulations ($global_simulations global simulations and $downscalings dynamical
  downscalings) that use $models climate models; $datasets datasets ($cmip5_datasets CMIP5, $cordex_cmip5_datasets
  CORDEX-CMIP5, $ukcp18_datasets UKCP18); $variables variables; $indices climate indices from $index_catalogues
  catalogues; $hazard_types hazard types; $operations operations and $methods methods of climate services.
- **Validation:** checked with the SHACL shapes of `shapes/` ($node_shapes node shapes, $property_shapes property
  shapes): $violations violations, $warnings warnings, $infos informative results.
- **Archive:** the dump (`kg.nq.gz`, gzipped N-Quads) and its description (`void.ttl`: DCAT, VoID, PROV-O, DQV),
  which says that it is this release, with its DOI.
- **Online:**
  - SPARQL endpoint: <https://w3id.org/climate-change-kg/sparql>
  - resources, which dereference: `https://w3id.org/climate-change-kg/data/...`
  - documentation: <https://w3id.org/climate-change-kg>

$graphs_table

## Sources

Every source is taken at a fixed version, given by the configuration of the workflow (`config/config.yaml`):

| Source | Version |
|:--|:--|
| HACID ontologies (top-level, data, CCSO; [hacid-project/knowledge-graph]($ontologies_repo)) | commit `$ontologies_commit_short` |
| CF Standard Name Table | version $cf_standard_names_version |
| CMOR tables | $cmor_tables_current, and $cmor_tables_previous_editions earlier editions for the previous variables |
| Climdex/Climpact indices | table of the Climpact user guide (v3.2/v3.3), sectors of climdex.org |
| ESGF publisher configuration (CMIP5 experiments and institutions) | commit `$esgf_config_commit` |
| CMIP5 datasets (ESGF search) | snapshot [$cmip5_snapshot_doi](https://doi.org/$cmip5_snapshot_doi) |
| CORDEX domain tables | commit `$cordex_domains_commit` |
| CORDEX regional models (IS-ENES Data) | commit `$cordex_rcms_commit` |
| CORDEX-CMIP5 datasets (ESGF search) | snapshot [$cordex_cmip5_snapshot_doi](https://doi.org/$cordex_cmip5_snapshot_doi) |
| UKCP18 datasets (CEDA) | snapshot [$ukcp18_snapshot_doi](https://doi.org/$ukcp18_snapshot_doi) |
| Indices, hazards, operations, methods, scenarios and global warming levels | curated in HACID, in this repository |

## What this tag contains

The tag $tag_link is the commit that built this release: the KG can be rebuilt from it (see the README,
`snakemake --cores 4 build`). The commit is also recorded in the metadata of the KG.

## Licences

- The code: MIT.
- The KG: CC BY 4.0. The licences of the sources are listed on the website and in the data descriptor.

## Funding

The KG was first developed in the European project HACID (Hybrid Human Artificial Collective Intelligence in Open-Ended
Decision Making), funded by the European Commission under Horizon Europe grant 101070588.
