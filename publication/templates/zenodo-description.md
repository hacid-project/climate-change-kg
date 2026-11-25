The **Climate Change Knowledge Graph (CCKG)** describes, as linked data, the climate information used by climate services:

- the climate variables (CF standard names, MIP variables of the CMOR tables, climate indices);
- the climate models and the simulations of CMIP5 and CORDEX-CMIP5, with their datasets;
- the UKCP18 datasets;
- the emissions scenarios and global warming levels;
- the controlled vocabularies of hazards, methods and operations of climate services.

It is described with the HACID ontologies (top-level, data and CCSO), and it was first developed in the European project
HACID (Hybrid Human Artificial Collective Intelligence in Open-Ended Decision Making).

**This record is the knowledge graph.** Its concept DOI, which always resolves to the latest version, identifies the
CCKG, and each version of the record is a release of it. Versions follow semantic versioning on what queries rely on:
the IRIs, the named graphs and the SHACL shapes.

- A **major** version breaks queries: removed or renamed IRIs, a change of the named graphs, an incompatible change of
  the shapes.
- A **minor** version adds content or structure: new sources, new properties, a newer snapshot of a source.
- A **patch** version only corrects values.

### Version $version

- **Build:** by the $workflow_link, released on $date. Previous version: $previous_link.
- **Size:** $triples_about triples ($triples, without inferred ones), in $named_graphs named graphs plus a named graph
  with the metadata of the KG.
- **Content:** $simulations simulations ($global_simulations global simulations and $downscalings dynamical
  downscalings) that use $models climate models, and $datasets datasets.
- **Validation:** checked with its SHACL shapes ($node_shapes node shapes, $property_shapes property shapes):
  $violations violations, $warnings warnings.

#### Changes

$changes

### Files

- `kg.nq.gz`: the whole knowledge graph, as gzipped N-Quads, with all its named graphs. It contains only the asserted
  triples, without the inferred ones.
- `void.ttl`: the description of the KG as a dataset, in Turtle:
  - title, creators, licence and distribution (DCAT), and this release as a version of the KG, with its DOI;
  - the named graphs and their statistics (VoID, SPARQL Service Description);
  - the build, the version of the workflow and the version of each source (PROV-O);
  - the results of the validation (DQV).

  The KG is described as `https://w3id.org/climate-change-kg`; the description is also in the dump, as the named graph
  `https://w3id.org/climate-change-kg/data/kg`.

$graphs_table

### Online access

The latest release is served online:

- **SPARQL endpoint:** <https://w3id.org/climate-change-kg/sparql>. Its default graph is the union of the named graphs,
  with the inferences of the RDFS-Plus ruleset of GraphDB.
- **Linked data:** every resource of the KG can be looked up at its IRI (`https://w3id.org/climate-change-kg/data/...`).
- **Documentation:** the content, the data model, competency questions with example queries, and the sources, at
  <https://w3id.org/climate-change-kg>.
- **SHACL shapes:** <https://w3id.org/climate-change-kg/shapes>.

### Use

The dump can be loaded in any RDF store that supports named graphs, e.g. with Apache Jena:

```
tdb2.tdbloader --loc cckg kg.nq.gz
```

The queries that rely on subclasses, subproperties or inverse properties need inference (at least RDFS, plus inverse
properties), as on the public endpoint.

### Sources and provenance

Every source is taken at a fixed version, so the release can be rebuilt with the workflow (tag $tag_link):

| Source | Version |
|:--|:--|
| HACID ontologies (top-level, data, CCSO) | commit `$ontologies_commit_short` of [hacid-project/knowledge-graph]($ontologies_repo) |
| CF Standard Name Table | version $cf_standard_names_version |
| CMOR tables | $cmor_tables_current, and $cmor_tables_previous_editions earlier editions for the previous variables |
| Climdex/Climpact indices | table of the Climpact user guide (v3.2/v3.3), sectors of climdex.org |
| ESGF publisher configuration (CMIP5 experiments and institutions) | commit `$esgf_config_commit` of [ESGF/config]($esgf_config_repo) |
| CORDEX domain tables | commit `$cordex_domains_commit` of [WCRP-CORDEX/domain-tables]($cordex_domains_repo) |
| CORDEX regional models (IS-ENES Data) | commit `$cordex_rcms_commit` of [IS-ENES-Data/IS-ENES-Data.github.io]($cordex_rcms_repo) |
| CMIP5 datasets (ESGF search) | snapshot [$cmip5_snapshot_doi](https://doi.org/$cmip5_snapshot_doi) |
| CORDEX-CMIP5 datasets (ESGF search) | snapshot [$cordex_cmip5_snapshot_doi](https://doi.org/$cordex_cmip5_snapshot_doi) |
| UKCP18 datasets (CEDA) | snapshot [$ukcp18_snapshot_doi](https://doi.org/$ukcp18_snapshot_doi) |
| Indices, hazards, operations, methods and scenarios | curated in HACID with the Met Office |

The full commits and the URLs of the sources are in `void.ttl`.

### Licence

The CCKG is released under CC BY 4.0. The sources and their licences are listed in the documentation and in the data
descriptor of the KG. The UKCP18 metadata, for instance, is under the Open Government Licence v3.0.

### How to cite

- **A specific release:** cite the DOI of its version (for reproducible results).
- **The CCKG in general:** cite the concept DOI of this record, $concept_doi_link.
- **The workflow:** cite $workflow_concept_link.

### Funding

The CCKG was first developed in the project HACID (Hybrid Human Artificial Collective Intelligence in Open-Ended
Decision Making), funded by the European Commission under the Horizon Europe programme, grant agreement 101070588.
