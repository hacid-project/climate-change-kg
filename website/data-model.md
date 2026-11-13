---
title: Data Model
layout: page
nav_order: 2
---

# Data Model

To favour interoperability, the knowledge graph is represented using semantic web standards, specifically using RDF a base data model and a network of ontologies to define and formalize the adopted schema.

The following ontologies are used in the graph:
- [HACID top-level ontology](https://w3id.org/hacid/onto/top-level), containing broad terms used throughout the [HACID project](https://www.hacid-project.eu/) and based mostly on the upper ontology [DOLCE-Ultralite](https://en.wikipedia.org/wiki/Upper_ontology#DOLCE);
- [Core Climate Services Ontology (CCSO)](https://w3id.org/hacid/onto/ccso), containing terms that are specific to the climate domain;
- [HACID data ontology module](https://w3id.org/hacid/onto/data), containing a semantically rich representation of datasets, variables, dimensional spaces.

The ontologies are developed in the [knowledge-graph](https://github.com/hacid-project/knowledge-graph) repository; each build of the knowledge graph uses them at a fixed commit (currently `61e336e`), loaded in the named graphs of their IRIs.

## Namespaces

| Prefix | Namespace | Used for |
|:-------|:----------|:---------|
| `top:` | `https://w3id.org/hacid/onto/top-level/` | top-level ontology |
| `data:` | `https://w3id.org/hacid/onto/data/` | data ontology module |
| `ccso:` | `https://w3id.org/hacid/onto/ccso/` | climate services ontology |
| | `https://w3id.org/hacid/data/cs/` | all the instances |
| `cf:` | `https://w3id.org/hacid/data/cs/variables/cf/` | CF standard variables |
| `mip:` | `https://w3id.org/hacid/data/cs/variables/mip/` | MIP variables (and, below `mip/<era>/<version>/`, previous variables) |
| `ukcp:` | `https://w3id.org/hacid/data/cs/variables/ukcp/` | local variables of UKCP18 |
| `sim:` | `https://w3id.org/hacid/data/cs/simulations/` | simulations and ensembles |
| `dataset:` | `https://w3id.org/hacid/data/cs/datasets/` | CMIP5 and CORDEX-CMIP5 datasets and outputs |
| `rcp:` | `https://w3id.org/hacid/data/cs/scenarios/RCP/` | RCP scenarios |
| `dimension:` | `https://w3id.org/hacid/data/cs/dimensions/` | dimensional spaces (time, geodetic, ...) |

## Main patterns

### Variables

A variable (`data:Variable`) takes values on a dimensional space (`data:hasValuesOn`) and, if it is a dependent variable, depends on other variables (`data:dependsOnVariable`, e.g., time and space).
Variables are organised by specialisation: a MIP variable such as `mip:tasmax` is a specialisation (`data:isSpecializationOfVariable`) of the CF variable `cf:air_temperature` (near the surface, with the maximum as aggregation in time), and a dataset holds a specialisation of its variable (`data:holdsSpecializationOfVariable`) restricted to its spatio-temporal coverage and granularity.
Other relations among variables are:
- `data:derivedFromVariable`, for a variable computed from others (e.g., a climate index from the variables it is based on);
- `data:isLinearTransformationOf`, for the same quantity in other units (e.g., a CMIP5 variable whose units changed in CMIP6, or `tas` in °C in UKCP18), and `data:hasOppositeValueOf`, for the opposite sign;
- `data:isEquivalentTo`, for variables with the same values (e.g., equivalent indices of different catalogues);
- `data:isAnomalyOf`, for an anomaly with respect to a baseline period (`data:hasBaselineRegion`), either a `data:AbsoluteAnomaly` or a `data:RelativeAnomaly` (a percentage change);
- `data:isProbabilisticRepresentationOf`, for the representation of the probability distribution of a variable, as a `data:ProbabilityDensityFunction`, a `data:QuantileFunction` (the values at given percentiles) or a `data:Sample`.

Variables are grouped in collections (`top:isMemberOf`), e.g., `https://w3id.org/hacid/data/cs/variables/cf`, `.../variables/mip`, `.../climdex/indices`.

### Dimensional spaces and quantisations

The values of the independent variables (time, space) are described by dimensional spaces, either continuous or discrete.
A dataset depends on a quantised version of time and space (e.g., a monthly series over a period, a grid of 0.44°), whose quantisation, with its resolution (`data:hasResolutionValue`), is given by `data:adoptsQuantization` (formerly `data:hasDiscretization`, still declared as a deprecated equivalent).
The spatial and temporal coverage of a dataset are given by its specialisations (`data:isSpecializedAccordingTo`), selecting a region (`data:hasSelectedRegion`) of a dimensional space.
Climate indices have suggested quantisations (`data:hasSuggestedQuantization`), e.g., yearly.

### Projections, simulations and ensembles

A dataset produced to project the climate is a `ccso:Projection`: a `ccso:SingleProjection`, an `ccso:EnsembleProjection` or a `ccso:ProbabilisticProjection`, referring to an emissions scenario (`ccso:ScenarioBasedProjection`) or to a global warming level.
Projections are produced by processes (`data:hasOutput`): simulations of climate models (`ccso:ClimateSimulation`, `ccso:usesModel`) or statistical transformations of other projections (`ccso:StatisticalProjectionTransformation`, e.g., `ccso:Rescaling`, `ccso:Aggregation`).

- A single simulation (`ccso:SingleSimulation`) is identified by its model, experiment and ensemble member; its output is made of datasets (`top:hasComponent`).
- The simulations of a model for an experiment form an ensemble (`ccso:PerturbedParameterClimateEnsembleSimulation`), and the ensembles of an experiment form a `ccso:ClimateModelIntercomparisonExperiment` (`top:hasComponent`); the outputs of the ensembles are ensemble projections.
- A dynamical downscaling (`ccso:DynamicalDownscaling`) is a simulation of a regional or local model driven by another simulation (`ccso:isDownscalingOf`), e.g., a CORDEX-CMIP5 simulation driven by a CMIP5 simulation, or a UKCP18 local simulation driven by a regional one.
- Climate models are global (`ccso:GlobalClimateModel`), regional (`ccso:RegionalClimateModel`) or convection-permitting (`ccso:ConvectionPermittingClimateModel`), maintained by institutions (`ccso:isMaintainedBy`).
- Emissions scenarios (`ccso:EmissionScenario`) are representative concentration pathways (`ccso:GreenhouseGasConcentrationPathway`) or shared socio-economic pathways (`ccso:SharedSocioeconomicPathway`); simulations refer to them by `ccso:refersToScenario`, and projections at a global warming level (`ccso:GlobalWarmingLevel`) by `ccso:refersToGlobalWarmingLevel`.

### Lineage of datasets

A dataset derived from others is linked to them, and to the process that derived it:
- `data:hasInput` relates a process to the datasets (or outputs) it takes as input, and `data:hasOutput` to its output;
- `data:hasRescaledVersion` relates a dataset to its versions on another grid or regional split (e.g., the UKCP18 probabilistic projections on the 25 km grid of the UK, or the regridded CMIP5 members of the UKCP18 global ensemble);
- `data:isLinearTransformationOf` and `data:isEquivalentTo` relate datasets with the same values in other or the same units (e.g., the UKCP18 EuroCORDEX datasets and the CORDEX-CMIP5 datasets they come from).

### Hazards and indices

A climate hazard is a type of climate phenomenon (`ccso:HazardType`), organised in a hierarchy (`top:specializes`), with the climate indices that are indicators of it (`ccso:hasIndicator`).

### Climate service workflow

The types of action performed to address a climate case are operations (`top:Operation`) and the ways of performing them are methods (`top:Method`), both organised in hierarchies (`top:specializes`).
An operation can define roles (`top:definesRole`) for the information it is associated with, with the expected type of that information (`top:hasExpectedType`).

## Inference

Many relations are declared in one direction and inferred in the other (e.g., `top:isMemberOf` and `top:hasMember`), and classes and properties are organised in hierarchies (e.g., a `ccso:GlobalClimateSimulation` is a `ccso:ClimateSimulation`).
The [example queries](example-queries) rely on such inferences (subclasses, subproperties, inverse and equivalent properties), which the public SPARQL endpoint provides.
