---
title: Data Sources
layout: page
nav_exclude: true
search_exclude: true
---

# Data Sources

This page gives the technical details of how each data source is integrated in the Climate Change Knowledge Graph: the versions used, what is taken from each source and how it is represented, and the named graphs. For an overview of what the knowledge graph contains, see [Content](content).

Every source is taken at a fixed version (a release, a git commit or a snapshot published on Zenodo), so that each version of the knowledge graph can be rebuilt from the same inputs.

The figures below refer to the current build of the knowledge graph, made by the [ingestion workflow](https://github.com/hacid-project/climate-change-kg) from the inputs listed for each source.

## Overview

{% assign release = site.data.releases.current %}
{% assign sources = release.sources %}
The versions and the numbers of datasets are those of release {{ release.version }} ({{ release.date }}).

| Source | Version used | Content in the KG |
|:-------|:-------------|:------------------|
| [CF Standard Name Table](https://cfconventions.org/Data/cf-standard-names/) | version {{ sources.cf_standard_names_version }} | 5,095 standard variables (600 aliases as alternative names) |
| CMOR tables ([CMIP5](https://github.com/PCMDI/cmip5-cmor-tables), [CMIP6](https://github.com/PCMDI/cmip6-cmor-tables), [CMIP6Plus](https://github.com/PCMDI/mip-cmor-tables)) | current edition {{ sources.cmor_tables_current }}; {{ sources.cmor_tables_previous_editions }} earlier editions for the previous variables | 1,323 MIP variables, 146 previous variables |
| [Climdex/Climpact indices](https://www.climdex.org/learn/indices/) | table of the Climpact user guide (v3.2/v3.3), indices by sector of climdex.org | 79 indices: the 63 of the table of the Climpact user guide, classified in 9 sectors, ETR (Extreme Temperature Range, not in the guide), and the 15 heatwave indices of each definition of the heatwaves (e.g. HWN_EHF, the heatwave number by the Excess Heat Factor) |
| Climate indices and hazards (curated in HACID) | — | 90 indices from ETCCDI (4), Climate-ADAPT (32, and 24 anomalies of them with respect to a baseline or as change), Copernicus C3S (6), UK-CRI (48); 42 hazard types, with 292 links to 109 indices |
| Climate service process (curated in HACID) | — | 81 operations, 60 methods, 11 schemes of values |
| Emissions scenarios and global warming levels | — | 8 RCPs and SRES A1B, 5 SSPs, 10 global warming levels (1.5 to 6 °C) |
| CMIP5 experiments and institutions ([ESGF publisher configuration](https://github.com/ESGF/config)) | commit `{{ sources.esgf_config_commit }}` | 102 experiments, 27 institutions, 63 models |
| CMIP5 datasets (ESGF search, [{{ sources.cmip5_snapshot_doi }}](https://doi.org/{{ sources.cmip5_snapshot_doi }})) | snapshot | {{ release.formatted.cmip5_datasets }} datasets of 5 experiments, 641 simulations in 152 ensembles, 41 global models |
| [CORDEX-CMIP5 domains and grids](https://github.com/WCRP-CORDEX/domain-tables) | commit `{{ sources.cordex_domains_commit }}` | 14 domains, 53 grids (rotated and regular) |
| CORDEX regional models ([IS-ENES Data](https://is-enes-data.github.io/CORDEX_RCMs_info.txt)) | commit `{{ sources.cordex_rcms_commit }}` | 101 regional models, 60 institutions |
| CORDEX-CMIP5 datasets (ESGF search, [{{ sources.cordex_cmip5_snapshot_doi }}](https://doi.org/{{ sources.cordex_cmip5_snapshot_doi }})) | snapshot | {{ release.formatted.cordex_cmip5_datasets }} datasets, 2,041 dynamical downscalings of 155 CMIP5 simulations, 45 regional models |
| UKCP18 datasets (CEDA, [{{ sources.ukcp18_snapshot_doi }}](https://doi.org/{{ sources.ukcp18_snapshot_doi }})) | snapshot | {{ release.formatted.ukcp18_datasets }} datasets (56,453 probabilistic), 30 global, 16 regional and 16 convection-permitting simulations, linked to 47 CMIP5 and 128 CORDEX-CMIP5 simulations |

Overall, the knowledge graph has {{ release.triples_about }} triples ({{ release.formatted.triples }}, without inferred ones), describing {{ release.formatted.simulations }} simulations ({{ release.formatted.global_simulations }} global simulations and {{ release.formatted.downscalings }} dynamical downscalings) that use {{ release.formatted.models }} climate models, and {{ release.formatted.datasets }} datasets.

## Climate variables, indices and hazards

- **Standard variables.** All the standard names of the [CF Metadata Conventions](https://cfconventions.org/) (version 95 of the table), with their description and units of measure. The aliases of the table are alternative names of the variables they stand for.
- **MIP variables.** The variables of the current edition of the CMOR tables (CMIP6Plus), one for each output name, as specialisations of the CF variables (`data:isSpecializationOfVariable`). Earlier editions of the CMOR tables (CMIP5 and CMIP6) sometimes define a variable with the same name in other units, with the opposite sign or as another quantity: such definitions are kept as distinct *previous variables* (e.g., [the CMIP5 `tos`, in K](https://w3id.org/climate-change-kg/data/variables/mip/cmip6/6.0.19/tos)), linked to the current variable by `data:isLinearTransformationOf` (change of units) or `data:hasOppositeValueOf` (change of sign). The variables of the datasets of all the projects are resolved to these variables from their definitions, not just their names.
- **Local variables.** The variables of the datasets that are not in the CMOR tables are defined locally: for CMIP5, a few variables of single models (e.g., the CanESM2 `orograw`); for CORDEX-CMIP5, the variables of the CORDEX standard output at single pressure or height levels (e.g., `ta200`, `ua50m`) and some variables of single models; for UKCP18, 160 variables, including anomalies, return levels and representations of probability distributions (see below).
- **Climate indices.** The indices of [Climdex](https://www.climdex.org/) (which extend the [ETCCDI indices](https://etccdi.pacificclimate.org/list_27_indices.shtml)), with their definition, the variable they are computed from and the suggested time granularities, classified by sector; and the indices of ETCCDI, [Climate-ADAPT](https://climate-adapt.eea.europa.eu/), [Copernicus C3S](https://climate.copernicus.eu/) and the [UK Climate Risk Indicators](https://uk-cri.org/), curated in the project, with the equivalences among indices of different catalogues.
- **Hazard types.** A hierarchy of climate hazard types, based mostly on the [Hazard Information Profiles](https://www.preventionweb.net/drr-glossary/hips) of UNDRR, each linked to the indices that are indicators of it (`ccso:hasIndicator`).

## Climate projections

- **CMIP5.** The metadata of the [CMIP5](https://pcmdi.llnl.gov/mips/cmip5/) datasets published on ESGF for the experiments `historical`, `rcp26`, `rcp45`, `rcp60`, `rcp85`: datasets, the outputs of the simulations, the simulations (one per ensemble member, including the fixed fields), the ensembles of the simulations of a model for an experiment, the experiments, the models and the institutions, the spatial and temporal grids and the temporal coverage. All the CMIP5 experiments of the ESGF configuration are described, even those without datasets in the KG.
- **CORDEX-CMIP5.** The metadata of the [CORDEX](https://cordex.org/) datasets of the CMIP5 era published on ESGF: datasets, simulations (dynamical downscalings, `ccso:isDownscalingOf`, of the CMIP5 simulation of the driving model), ensembles and experiments, regional models and institutions, CORDEX domains and grids. The driving CMIP5 simulations are in the KG even when their datasets are not in the CMIP5 search results. The evaluation runs, driven by the ERA-Interim reanalysis, are kept apart from the historical runs.
- **UKCP18.** The metadata of the [UK Climate Projections 2018](https://www.metoffice.gov.uk/research/approach/collaboration/ukcp) datasets published by CEDA (all the collections but `marine-sim`): the global (60 km), regional (12 km) and local (2.2 km, convection-permitting) projections of the Met Office Hadley Centre, with the chain of downscalings from global to regional to local; the probabilistic projections (`land-prob`), as probability density functions, quantile functions or samples of anomalies with respect to a baseline period (1961-1990, 1981-2000, 1981-2010) and of return levels; the derived projections and indices, including those at global warming levels of 2 and 4 °C; the CMIP5 members of the global ensemble and the EuroCORDEX members, linked to the CMIP5 and CORDEX-CMIP5 simulations and datasets they come from.
- **Lineage.** The datasets derived from other datasets are linked to them and to the process that derived them: the versions of a dataset on other grids or regional splits (`data:hasRescaledVersion`), the datasets in other units (`data:isLinearTransformationOf`) or with the same values (`data:isEquivalentTo`), and the processes (rescalings, aggregations, statistical transformations) with their inputs (`data:hasInput`) and outputs.

## Climate service workflow

- **Operations.** A hierarchy of the types of action performed to address a climate case (e.g., the selection of climate models or the identification of the relevant indices), with the type of information associated with each of them.
- **Methods.** A hierarchy of the methods that can be adopted to perform such actions (e.g., bias correction methods).
- **Schemes of values.** The controlled vocabularies used to describe a climate case (e.g., sectors, organisation types, confidence levels).

## Named graphs

Each source is loaded in its own named graph; the default graph of the SPARQL endpoint is the union of all of them.

| Named graph | Content | Triples |
|:------------|:--------|--------:|
| `https://w3id.org/hacid/onto/top-level`, `.../onto/data`, `.../onto/ccso` | the ontologies | 3,197 |
| `https://w3id.org/climate-change-kg/data` | collections, dimensions, scenarios, global warming levels | 209 |
| `https://w3id.org/climate-change-kg/data/cf` | CF standard names | 31,578 |
| `https://w3id.org/climate-change-kg/data/cmor-tables` | MIP variables and previous variables | 16,757 |
| `https://w3id.org/climate-change-kg/data/climdex` | Climdex indices and sectors | 1,571 |
| `https://w3id.org/climate-change-kg/data/mohc-cvs` | indices, hazards, operations and methods curated in HACID | 2,815 |
| `https://w3id.org/climate-change-kg/data/cmip5/cvs` | CMIP5 experiments, institutions and models | 884 |
| `https://w3id.org/climate-change-kg/data/cmip5/datasets` | CMIP5 datasets | 282,822 |
| `https://w3id.org/climate-change-kg/data/cordex/cvs` | CORDEX domains, grids and regional models | 1,576 |
| `https://w3id.org/climate-change-kg/data/cordex-cmip5/datasets` | CORDEX-CMIP5 datasets | 1,557,129 |
| `https://w3id.org/climate-change-kg/data/ukcp18` | UKCP18 datasets | 3,777,065 |
| `https://w3id.org/climate-change-kg/data/indices`, `.../data/variables` | collections merged by the consolidation | 6,770 |
| `https://w3id.org/climate-change-kg/data/kg` | metadata of the knowledge graph | 2,269 |

## Decisions on the sources

The issues, inconsistencies and conflicting versions found in each source, and the decisions taken on them (including the cases left for further analysis), are documented with the source in the [ingestion repository](https://github.com/hacid-project/climate-change-kg) (`data-sources/<source>/DECISIONS.md`).
