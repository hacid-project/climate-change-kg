# Changelog

The changes of each release of the Climate Change Knowledge Graph and of its workflow. Write the changes in the section
**Unreleased** as they are made: the release (`snakemake --cores 4 release --config version=X.Y.Z`) moves them to the
section of the new version, and quotes them in the release notes, in the GitHub release and on Zenodo. Versions follow
[semantic versioning](https://semver.org/) on what queries rely on (IRIs, named graphs, SHACL shapes): see the README.

## Unreleased

## 1.2.1 - 2026-11-27

### Knowledge graph

- The ontologies are taken at the commit `48d5aaf` of `hacid-project/knowledge-graph` (was `bfb0310`), which changes
  only the metadata of their headers, not their axioms: creators by ORCID (top-level: A. G. Nuzzolese, A. Russo,
  M. Ceriani; data and CCSO: M. Ceriani, A. G. Nuzzolese, in CCSO in place of the IRIs of the old namespace), licence
  CC BY 4.0 in all, version 1.0 of top-level and data (`owl:versionIRI`, `owl:versionInfo`), `owl:versionInfo` 2.1 of
  CCSO, `dcterms:created` and `dcterms:modified`, and the declarations of the Dublin Core terms they use.
- The expected types of the information roles whose values are ranges of literals (a period as two dates, a range of
  numbers or durations; 7 roles, e.g. `ops:ChooseBaselinePeriod/associated-data`) are well-formed OWL class
  expressions: the intersection of their two restrictions is typed `owl:Class`, as the other class expressions, and
  `owl:cardinality` is an `xsd:nonNegativeInteger`, as the RDF mapping of OWL 2 requires (it was an `xsd:integer`).
  Their meaning is unchanged: the class of the datatype restrictions on the datatype of the values, with one list of
  facets (`data-sources/mohc-cvs/mapping/operations.jq`).

### Deployment

- The endpoint loads only the dump `kg.nq.gz` of a release, not `void.ttl` too (`excludeFiles` in
  `deployment/kgserve/config.json`): the description of the KG was in the endpoint twice, also as the graph
  `https://doi.org/10.5281/zenodo.24305088#void.ttl` (2,371 triples for release 1.2.0), a copy of the graph
  `https://w3id.org/climate-change-kg/data/kg` of the dump.

## 1.2.0 - 2026-11-26

### Knowledge graph

- The CORDEX-CMIP5 runs of the two statistical downscaling models, `BOM-SDM` (Bureau of Meteorology, domain `AUS`,
  66 runs, 199 datasets) and `DeepESD-EE` (University of Cantabria, domain `EUR-44i`, 16 runs, 32 datasets), are
  statistical downscalings (`ccso:StatisticalDownscaling`; a run is a `ccso:SingleProjectionProduction`, its
  ensembles `ccso:EnsembleProjectionProduction`s), no longer dynamical downscalings, which are climate simulations
  (`ccso:DynamicalDownscaling`, `ccso:SingleSimulation`, `ccso:EnsembleSimulation`). A run is still linked to the CMIP5
  simulation it downscales (`ccso:isDownscalingOf`). Its model is a participant (`top:hasParticipant`) instead of
  `ccso:usesModel`, which is for climate models, and the two models are a `top:Description` with a comment and a
  reference (`rdfs:seeAlso`), no longer a `ccso:RegionalClimateModel`. The experiments of the domain `AUS` are
  statistical downscalings too; those of `EUR-44i` (historical and rcp85), with runs of both kinds, are a
  `ccso:Downscaling` and a `ccso:EnsembleProjectionProduction`, no longer a `ccso:ClimateModelIntercomparisonExperiment`
  and a `ccso:DynamicalDownscaling` (`consolidation/CORDEX-statistical-experiments.ru`). The CORDEX-CMIP5 graph has
  1,959 dynamical and 82 statistical downscaling runs (2,041 dynamical before). Queries for the climate simulations or
  for `ccso:usesModel` no longer return them; queries for `ccso:Downscaling` or `ccso:isDownscalingOf` still do. See
  `data-sources/cordex-cmip5/DECISIONS.md`. The key figures count 82 simulations fewer, and the two models no longer
  among the climate models; the Sources page of the website gives the downscalings of each kind.
- The runs of `DeepESD-EE` (the statistical downscalings with a CORDEX grid) are described (`rdfs:comment`) as
  statistical downscalings by their statistical model, no longer as RCM simulations
  (`consolidation/CORDEX-comment-generation.ru`). The outputs of the statistical downscalings keep the temporal
  coverage of their datasets, as those of the simulations (`consolidation/simTimeCoverage-local.ru`; for `BOM-SDM`,
  whose datasets have time intervals).

### Shapes

- `shape:StatisticalDownscaling`: a statistical downscaling uses no climate model (`ccso:usesModel`).
  `shape:DownscalingRun` also checks the runs of the statistical downscalings (they downscale a simulation), and
  `shape:ProjectionTransformation` leaves out all the downscalings, whose runs are linked to what they downscale by
  `ccso:isDownscalingOf`.

## 1.1.1 - 2026-11-25

### Knowledge graph

- The KG, as a dataset, is `https://w3id.org/climate-change-kg`, the root of the namespace of the project (as for an
  ontology), no longer `https://w3id.org/climate-change-kg/data/kg`, which named both the KG and the graph of its
  metadata. That graph keeps its name, now the IRI of the description of the KG (`void:DatasetDescription`, with
  `foaf:primaryTopic` the KG), under which the resources of the description keep their IRIs (distribution, releases,
  builds, partitions, quality measurements). The statistics, the creators, the provenance and the quality measurements
  are those of the root, and a release is also its current version (`dcat:hasCurrentVersion`). The KG no longer has
  its website as `foaf:homepage`, an inverse functional property (the website stays its `dcat:landingPage`). Queries
  on the metadata that use `<https://w3id.org/climate-change-kg/data/kg>` as the dataset are to use the root; the
  named graphs are unchanged. The redirect of the root to the description for RDF clients is still to be submitted to
  w3id.org (`publication/w3id/README.md`).

### Workflow

- The number of climate indices of the key figures (`metadata/figures.rq`) no longer counts the anomalies of an index
  (the 24 of Climate-ADAPT, members of its catalogue): 169 indices in 5 catalogues, as on the Sources page of the
  website, instead of 193. The 79 Climdex indices are the 63 of Climdex, the 15 specialisations of its heatwave indices
  by computation method (which Climdex does not count) and ETR; the 90 curated ones are those of ETCCDI, Climate-ADAPT,
  C3S and UK-CRI. The website shows 169 for releases 1.0.0 and 1.1.0
  (`website/_data/releases.json`). The notes of release 1.1.0 say 193, with a correction note; its GitHub release
  says 193.
- `doc/conventions.md` no longer reports the warning on the English alternative labels, gone since `top:altLabel` has
  the range `rdfs:Literal` (release 1.1.0).

## 1.1.0 - 2026-11-25

### Knowledge graph

- The ontologies are at commit `bfb0310` of hacid-project/knowledge-graph (CCSO 2.1), consistent with DOLCE+DnS
  Ultralite and with the KG: the global warming levels are descriptions (`top:Description`, no longer
  `top:Parameter`), linked to projections and productions by `ccso:refersToGlobalWarmingLevel` under
  `top:isDescribedBy` (no longer `top:isClassifiedBy`); `top:altLabel` allows language tags (range `rdfs:Literal`).
- The metadata of the KG (`void.ttl`) lists its nine creators (from `metadata/record.yaml`, shared with the record on
  Zenodo), describes the release as a version of the KG with its DOI and the previous release (DCAT 3), points to the
  repository under its current name (`hacid-project/climate-change-kg`), and to the SHACL shapes at
  `https://w3id.org/climate-change-kg/shapes`.

### Workflow

- `snakemake --cores 4` builds the whole KG, validated, with its metadata (target `build`), and
  `snakemake --cores 4 release --config version=X.Y.Z` releases it on GitHub and Zenodo.
- The key figures of the KG (models, simulations, datasets, variables, indices, ...) are computed by a query
  (`metadata/figures.rq`), and the website reads them, with the other facts of the releases, from
  `website/_data/releases.json`.
- The Zenodo snapshots of the CMIP5, CORDEX-CMIP5 and UKCP18 metadata are given in `config/config.yaml`.
- The documentation website is in `website/`; the query of CQ19 no longer lists current MIP variables as previous ones.

## 1.0.0 - 2026-11-15

The first release in the namespace `https://w3id.org/climate-change-kg/` (see `publication/releases/v1.0.0.md`), with
the files of version 15 of the earlier record on Figshare.
