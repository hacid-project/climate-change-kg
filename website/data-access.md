---
title: Data Access
layout: page
nav_order: 3
---

# Data Access

The data can be accessed in multiple ways. The data are open, published under [Creative Commons Attribution 4.0 International license (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).

## Query the SPARQL Endpoint

A public SPARQL endpoint is available at [w3id.org/hacid/cs/sparql](https://w3id.org/hacid/cs/sparql).
It can be queried both programmatically and via browser using the user interface available at the same URL.

You can start by checking the [example queries](example-queries).

## Navigate as Linked Data

All the URIs used in the knowledge graph can be dereferenced, either programmatically or via browser, in order to get information on that resource (namely, all triples having such resource as subject or object). This allows to navigate the knowledge graph going from one resource to another.

Example resource URIs:
- [air_temperature (CF variable)](https://w3id.org/hacid/data/cs/variables/cf/air_temperature);
- [tasmax (MIP variable)](https://w3id.org/hacid/data/cs/variables/mip/tasmax);
- [WSDI (Warm Spell Duration Indicator)](https://w3id.org/hacid/data/cs/climdex/indices/WSDI);
- [HadCM3 (global climate model maintained by the MetOffice, UK)](https://w3id.org/hacid/data/cs/models/HadCM3);
- [CMIP5 global simulation using the model HadCM3 for the RCP4.5 scenario (realization 1)](https://w3id.org/hacid/data/cs/simulations/cmip5.HadCM3.rcp45.r1i1p1);
- [CORDEX regional downscaling for south-america considering the RCP8.5 scenario, using the model CanESM2 for the global simulation and the model WRF341I for downscaling](https://w3id.org/hacid/data/cs/simulations/cordex.SAM-44.CanESM2.rcp85.WRF341I.v2.r1i1p1);
- [HadREM3-RA11M (convection-permitting model of the MetOffice, UK, used by the UKCP18 local projections)](https://w3id.org/hacid/data/cs/models/HadREM3-RA11M);
- [anomaly of the near-surface air temperature with respect to 1981-2000 (UKCP18 variable)](https://w3id.org/hacid/data/cs/variables/ukcp/tasAnom/1981-2000);
- [the CMIP5 definition of tos, in K, kept as a previous MIP variable](https://w3id.org/hacid/data/cs/variables/mip/cmip6/6.0.19/tos).

## Download the Dumps

At the DOI [10.6084/m9.figshare.29066711](https://dx.doi.org/10.6084/m9.figshare.29066711), snapshots of the entire knowledge graph will be periodically published, as N-Quads.

## Named Graphs

The data of each source are in their own named graph, while the default graph of the SPARQL endpoint is the union of all of them:

| Named graph | Content |
|:------------|:--------|
| `https://w3id.org/hacid/onto/top-level`, `https://w3id.org/hacid/onto/data`, `https://w3id.org/hacid/onto/ccso` | the ontologies |
| `https://w3id.org/hacid/data/cs` | scenarios, global warming levels, dimensions, collections |
| `https://w3id.org/hacid/data/cs/cf` | CF standard variables |
| `https://w3id.org/hacid/data/cs/cmor-tables` | MIP variables |
| `https://w3id.org/hacid/data/cs/climdex` | Climdex indices |
| `https://w3id.org/hacid/data/cs/mohc-cvs` | other indices, hazard types, climate service operations and methods |
| `https://w3id.org/hacid/data/cs/cmip5/cvs`, `https://w3id.org/hacid/data/cs/cmip5/datasets` | CMIP5 experiments, institutions, models, simulations and datasets |
| `https://w3id.org/hacid/data/cs/cordex/cvs`, `https://w3id.org/hacid/data/cs/cordex-cmip5/datasets` | CORDEX domains, regional models, simulations and datasets |
| `https://w3id.org/hacid/data/cs/ukcp18` | UKCP18 models, simulations and datasets |
| `https://w3id.org/hacid/data/cs/indices`, `https://w3id.org/hacid/data/cs/variables` | collections of all the indices and variables |

## Build the Knowledge Graph

The knowledge graph can also be rebuilt from its sources with the [ingestion workflow](https://github.com/hacid-project/climate-services-kg) (a [Snakemake](https://snakemake.github.io/) workflow, with the mappings written in jq): every source is taken at a fixed version, so the same inputs give the same graph.
The workflow loads the mapped sources into an [Apache Jena](https://jena.apache.org/) TDB2 dataset, applies the consolidation updates and exports the dataset as N-Quads; the dataset can then be queried locally with Fuseki.
Note that the local endpoint applies no inference: the [example queries](example-queries) that rely on subclasses, subproperties or inverse properties (see [Data Model](data-model#inference)) need an endpoint with inference.
