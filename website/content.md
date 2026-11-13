---
title: Content
layout: page
nav_order: 1
---

# Content

The Climate Change Knowledge Graph includes and integrates data from multiple heterogeneous sources.
It brings together the descriptions of climate projections produced by international and national projects, the vocabularies used to describe their variables, and knowledge on climate hazards and climate services, so that all of them can be explored and queried as a whole.

## At a glance

| Content | Amount |
|:--|:--|
| Climate models | 94 (global, regional and convection-permitting) |
| Simulations | about 2,800 (global simulations and dynamical downscalings) |
| Datasets | about 568,000 |
| Climate variables | about 6,900 (standard, MIP and project-specific variables) |
| Climate indices | 153, from 5 catalogues |
| Hazard types | 42 |
| Climate service operations and methods | 81 operations, 60 methods |

## Climate variables and indices

- standard variables defined by the [CF Metadata Conventions](https://cfconventions.org/);
- MIP variables defined in the [CMOR Tables](https://github.com/PCMDI/mip-cmor-tables) of CMIP (they are aggregations/specializations of the CF variables), including the earlier definitions that changed across the editions of the tables (e.g., a variable whose units changed from CMIP5 to CMIP6);
- variables specific to some projects or models, such as the anomalies with respect to a baseline period and the probabilistic variables of UKCP18;
- climate indices defined in [Climdex](https://www.climdex.org/), which are an extension of the [ETCCDI Climate Change Indices](https://etccdi.pacificclimate.org/list_27_indices.shtml), classified by sector;
- further climate indices from [Climate-ADAPT](https://climate-adapt.eea.europa.eu/), the [Copernicus Climate Change Service](https://climate.copernicus.eu/) and the [UK Climate Risk Indicators](https://uk-cri.org/), with the equivalences among indices of different catalogues.

## Climate hazards

- a hierarchy of climate hazard types (e.g., droughts, floods, heatwaves), based mostly on the [Hazard Information Profiles](https://www.preventionweb.net/drr-glossary/hips) of UNDRR;
- for each hazard type, the climate indices that are relevant indicators of it.

## Emissions scenarios and global warming levels

- the Representative Concentration Pathways (RCPs), the Shared Socioeconomic Pathways (SSPs) and the SRES A1B scenario;
- global warming levels from 1.5 to 6 °C.

## Climate models, simulations and datasets

- metadata from the main [CMIP5](https://pcmdi.llnl.gov/mips/cmip5/) experiments (historical and RCPs): global climate models and the institutions maintaining them, simulations, ensembles and their datasets;
- metadata from the [CORDEX](https://cordex.org/) regional experiments of the CMIP5 era: regional climate models, the CORDEX domains and grids, and the dynamical downscalings of the CMIP5 simulations;
- metadata from the [UK Climate Projections 2018 (UKCP18)](https://www.metoffice.gov.uk/research/approach/collaboration/ukcp) of the Met Office: global, regional and local (convection-permitting) projections, probabilistic projections, derived projections and indices, including projections at global warming levels.

For all of them, the knowledge graph describes which model produced each simulation, under which scenario, which variables each dataset provides, and with which spatial and temporal coverage and resolution.
It also connects the projections of the different projects: the chains of downscalings from global to regional to local simulations, and the datasets derived from other datasets (e.g., regridded, aggregated or converted to other units).

## Climate service process

- a hierarchy of the types of action performed by climate service providers to address a climate case (e.g., the selection of climate models or the identification of the relevant indices), with the type of information associated with each of them;
- a hierarchy of the methods that can be adopted to perform such actions (e.g., bias correction methods);
- the controlled vocabularies used to describe a climate case (e.g., sectors, organisation types, confidence levels).
