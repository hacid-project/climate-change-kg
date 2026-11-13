# Conventions of the KG: text properties and IRIs

This document records the conventions followed by the mappings for the text properties of the resources
(`rdfs:label`, `top:acronym`, `rdfs:comment`) and for their IRIs, as found in the consolidated KG, together with the
variations and the open cases left for a future review. It describes the data graphs (namespace
`https://w3id.org/climate-change-kg/data/`), not the ontologies, which are loaded as published.

## Text properties

### The rule

| Kind of value | Language | Examples |
| --- | --- | --- |
| An identifier or a standard name | none (`xsd:string`) | the id of a dataset or of a simulation, the name of a model, a CF standard name, the symbol of a unit, an acronym |
| Text | English (`@en`) | the long name of a variable, the name of an organization, the description of a grid |

No other language is used. The shapes check it (`shapes/generic.ttl`): a label is without language or in English
(`shape:Resource-label`, and likewise an alternative label, `shape:Resource-altLabel`), an acronym is without
language (`shape:Resource-acronym`), a comment and a definition are in English (`shape:Resource-comment`,
`shape:Resource-definition`); the classes whose instances have labels of both kinds are listed, as information, by
`shape:LabelLanguage`.

### `rdfs:label`

| Resources | Label | Language | Source |
| --- | --- | --- | --- |
| Datasets (CMIP5, CORDEX-CMIP5, UKCP18) | the id of the dataset (for UKCP18 `ukcp18.<id>`, without `.nc`) | none | `cmip5-datasets.jq`, `cordex-datasets.jq`, `ukcp18/mapping/datasets.jq` |
| Outputs of simulations, ensembles and derivations | their id (e.g. `cmip5.ACCESS1-0.rcp45.r1i1p1.output1`) | none | the same, `ukcp18/mapping/simulations.jq` |
| Outputs of experiments and of CORDEX domains | `output of <id>` | `en` | `cmip5-datasets.jq`, `cordex-datasets.jq` |
| Simulations, ensembles, CORDEX experiments and domains, UKCP18 derivations | their id | none | the same |
| CMIP5 experiments | their description (e.g. "Historical") | `en` | `cmip5-cvs/mapping/experiments.jq` |
| UKCP18 processings of other sources | `processing of <ids> for <id>` | `en` | `ukcp18/mapping/simulations.jq` |
| Models | their name (e.g. `HadGEM2-ES`) | none | `cmip5-datasets.jq`, `cordex-datasets.jq`, `cordex-cmip5-cvs/mapping/models.jq`, `ukcp18/mapping/models.jq` |
| Organizations | their name | `en` | `cmip5-cvs/mapping/institutions.jq`, `cordex-cmip5-cvs/mapping/models.jq` |
| People | their name | none | `data-sources/people.ttl` |
| CF variables | the standard name | none | `cf-standard-names/mapping/standard-names.jq` |
| MIP variables, local variables of CMIP5, CORDEX and UKCP18 | `<long name> (<name>[, <qualifier>])` | `en` | `cmor-tables/mapping/variables-jsonld.jq`, `ukcp18/mapping/ukcp18-variables.jq` |
| Climdex and MOHC indices, parameters of the indices | their name | `en` | `climdex/mapping/climdex.jq`, `mohc-cvs/mapping/indices.jq` |
| Units of measure | their symbol | none | all the mappings of variables, `climdex/added-units.ttl` |
| Sectors, values of the schemes, hazard types, operations, methods | their name | `en` | `climdex/mapping/by_sector.jq`, `mohc-cvs/mapping/*.jq` |
| CORDEX domains and grids | `CORDEX:<id>` | none | `cordex-domains/mapping/domains.jq` |
| Dimensions, reference frames, regions, points, time intervals, other grids, quantizations | a description | `en` | `common-spacetime.ttl`, `cordex-domains/mapping/domains.jq`, `ukcp18/mapping/spatial-grids.jq`, `time.jq`, `esgf.jq` |
| Collections, scenarios | their name | `en` | `collections.ttl`, `scenarios.ttl`, the mappings of the local variables |
| Model intercomparison projects | their acronym (`CMIP5`) | none | `mips.ttl` |
| Outputs of the projects | `CMIP5 output` | `en` | `mips.ttl` |
| Global warming levels | `GWL<level>` | none | `gwls/mapping/gwls.jq` |

Classes with labels of both kinds (`shape:LabelLanguage`), each because it has resources named by an identifier and
resources with a descriptive label:

| Class | Without language | In English | Possible alignment |
| --- | --- | --- | --- |
| `data:DeterministicVariable` | the CF variables (standard names) | the MIP and local variables (long names) | none: both follow the rule |
| `ccso:ScenarioBasedProjection`, `ccso:EnsembleProjection` | ids | "output of ..." of the experiments and domains | an id as label (e.g. `cmip5.rcp45.output`) |
| `ccso:StatisticalProjectionTransformation` (with `ccso:Aggregation`, `ccso:Rescaling`) | the ids of the derivations | "processing of ... for ..." | an id as label, or the text as comment |
| `ccso:ClimateModelIntercomparisonExperiment`, `ccso:GlobalClimateSimulation` | the ids of the CORDEX experiments and of the simulations | the descriptions of the CMIP5 experiments | the id of the experiment as label (it is its `top:acronym`) and the description as comment |
| `top:Concept` | the CORDEX domains (`CORDEX:AFR`) | sectors and values of the schemes | none: both follow the rule |
| `data:ProbabilityDensityFunction`, `data:QuantileFunction`, `data:Sample` | the UKCP18 probabilistic datasets (ids) | the variables they represent | none: datasets and variables share the class |

Other open cases:

- **More than one name.** A variable of the CMOR tables with a different long name in each table (e.g.
  `variables/mip/prra`) has the shortest as label and the others as `top:altLabel`. The update
  `consolidation/unify-labels.ru` keeps, among the English labels of a resource, the one contained in all the others,
  if any.
- **No label.** The grids of the datasets (temporal grids, `simulations/<id>/geodetic-grid`), the specializations,
  the quantizations of time, the information roles of the operations and the datasets by grid of the UKCP18 outputs
  have no label.
- **Names of the units.** The labels of the units are their symbols as written by each source (`degC`, `°C`, `K`,
  `proportion of time`): they are not normalised across the sources.

### `top:acronym`

Always an identifier, without language.

| Resources | Acronym | Source |
| --- | --- | --- |
| MIP and local variables | their name in the tables or in the datasets (e.g. `tas`, `tasAnom`) | `cmor-tables/mapping/variables-jsonld.jq`, `cordex-cmip5/mapping/variables.jq`, `ukcp18/mapping/ukcp18-variables.jq` |
| Climdex indices and their parameters | their short name (e.g. `TX10p`, `n`) | `climdex/mapping/climdex.jq` |
| Organizations | their id in the source (e.g. `MOHC`) | `cmip5-cvs/mapping/institutions.jq`, `cordex-cmip5-cvs/mapping/models.jq`, `cmip5-datasets.jq`, `cordex-datasets.jq` |
| CMIP5 experiments | their id (e.g. `rcp45`) | `cmip5-cvs/mapping/experiments.jq` |
| Scenarios | `RCP 4.5`, `SSP 1` | `scenarios.ttl` |

Open cases:

- The acronyms of the scenarios have a space (`RCP 4.5`), unlike their ids in the sources and in their IRIs
  (`RCP4.5`).
- The CF variables, the MOHC indices, the models, the CORDEX experiments and the UKCP18 simulations have no acronym:
  their identifier is their label. For the CMIP5 experiments it is also in `top:componentIdentifier`.

### `rdfs:comment`

Always text, in English.

| Resources | Comment | Source |
| --- | --- | --- |
| CF variables | the description of the standard name | `cf-standard-names/mapping/standard-names.jq` |
| MIP and local variables | the comment of the tables | `cmor-tables/mapping/variables-jsonld.jq` |
| Climdex indices | their description | `climdex/mapping/climdex.jq` |
| Operations | their description | `mohc-cvs/mapping/operations.jq` |
| Outputs of the CMIP5 simulations | the descriptions of their datasets (e.g. "HadGEM2-ES model output prepared for CMIP5 RCP2.6") | `cmip5-datasets.jq` |
| CMIP5 and CORDEX-CMIP5 single simulations | a generated description (experiment, models, institutes, domain, member) | `consolidation/CMIP5-comment-generation.ru`, `CORDEX-comment-generation.ru` |
| Dimensions, reference frames, regions, points, time intervals, grids | a description | as for their labels |
| Collections, scenarios, projects, global warming levels | a description | the files written by hand, `gwls/mapping/gwls.jq` |

Open cases:

- **Generated comments.** The comments of the simulations are built by the consolidation from the labels of other
  resources, some without language (models) and some in English (experiments, organizations): the result is tagged as
  English as a whole.
- **Text of the sources.** The comments taken from the sources (CF descriptions, CMOR comments, ESGF descriptions)
  are tagged as English without checking their language; some are terse notes rather than sentences.
- **No comment.** Datasets, most outputs, ensembles, models (but one), organizations, units and the MOHC indices have
  no comment.
- **Other text properties.** The rule applies to them as well:

  | Property | Values | Language | Check |
  | --- | --- | --- | --- |
  | `top:definition` | the definitions of the Climdex and MOHC indices (text) | `en` | `shape:Resource-definition` |
  | `top:altLabel` | the aliases of the CF standard names (standard names) | none | `shape:Resource-altLabel` |
  | `top:altLabel` | the alternative names of the methods and the other long names of the MIP variables (text) | `en` | `shape:Resource-altLabel` |
  | `top:name` | the names of the people | none | |
  | `top:componentIdentifier`, `ccso:productId` | ids of experiments, ensemble members, products | none | |
  | `dcterms:title` | the titles of the shared socioeconomic pathways (text) | `en` | |

  The top-level ontology gives `top:altLabel` the range `xsd:string`, so its values in English are reported by
  `shape:PropertyDatatype` (a warning): either the range is widened in the ontology (e.g. to `rdfs:Literal`, as for
  `top:name`), or the alternative names of the methods lose their language.

## IRIs

All the resources are in the namespace `https://w3id.org/climate-change-kg/data/` (below, IRIs are relative to it), with
`/` as the only separator: there are no fragment identifiers but in the metadata of the KG (`<graph>#graph`, see
`metadata/kg.ttl`). The local names are percent-encoded by the mappings (`@uri` in jq).

### Schemes in use

| Resources | IRI | Example |
| --- | --- | --- |
| **Variables** | | |
| CF variables | `variables/cf/<standard name>` | `variables/cf/air_temperature` |
| MIP variables (current edition) | `variables/mip/<name>` | `variables/mip/tas` |
| Previous MIP variables | `variables/mip/<era>/<name>`, `variables/mip/<era>/<version>/<name>` | `variables/mip/cmip5/dms`, `variables/mip/cmip6/6.0.19/tos` |
| CMIP5 variables of a model | `variables/cmip5/<model>/<name>` | `variables/cmip5/CanESM2/orograw` |
| CORDEX variables | `variables/cordex/<name>` | `variables/cordex/ta200` |
| CORDEX variables of a model | `variables/cordex/<model>/<name>/<units>` | `variables/cordex/BOM-SDM/pr/mm` |
| UKCP18 variables | `variables/ukcp/<name>`, then `/<units>`, `/<baseline years>`, `/rp<return period>`, and `/pdf`, `/cdf`, `/sample` | `variables/ukcp/tasAnom/1981-2000/cdf` |
| Climdex indices, parameters, aggregations, sectors | `climdex/indices/<short name>`, `climdex/parameters/<id>`, `climdex/index-time-aggregations/<short name>`, `climdex/sectors/<name>` | `climdex/indices/FD` |
| MOHC indices | `<scheme>/indices/<Name in camel case>`, then `/<variant>[/<reference period>]` | `Climate-ADAPT/indices/HighSnowDays/change-absolute` |
| Units of measure | `unitsofmeasure/<symbol>` | `unitsofmeasure/K%20m%20s-1` |
| Collections of variables | the IRI the variables are under | `variables/mip`, `climdex/indices`, `variables/cordex/<model>`, `realms/<realm>` |
| **Datasets and outputs** | | |
| CMIP5 and CORDEX-CMIP5 datasets | `datasets/<id>` | `datasets/cmip5.output1.MOHC.HadGEM2-ES.rcp85.mon.atmos.Amon.r1i1p1` |
| Outputs of their simulations, ensembles | `datasets/<simulation id>.<product>`, `datasets/<ensemble id>[.<product>]` | `datasets/cmip5.HadGEM2-ES.rcp85.r1i1p1.output1` |
| Outputs of the CMIP5 experiments | `datasets/cmip5.<experiment>/output` | `datasets/cmip5.rcp85/output` |
| Outputs of the projects | `mips/<project>/output` | `mips/cmip5/output` |
| UKCP18 datasets | `ukcp18/datasets/<file name>` | `ukcp18/datasets/tas_rcp85_land-rcm_uk_12km_01_mon_198012-208011.nc` |
| UKCP18 datasets of EuroCORDEX and their parts | `ukcp18/EuroCORDEX/datasets/<CORDEX id>[/<experiment>]` | `ukcp18/EuroCORDEX/datasets/cordex.output.EUR-11...mon.tas/historical` |
| UKCP18 datasets of the CMIP5 members | `ukcp18/land-gcm/datasets/<scenario>.<member>` | `ukcp18/land-gcm/datasets/rcp26.16` |
| Outputs of the UKCP18 simulations and derivations | `simulations/<id>/output`, `derivations/<id>/output` | `simulations/ukcp18.regional.rcp85.01/output` |
| Outputs of the UKCP18 ensembles by collection | `ukcp18/<collection>/datasets/<scenario>/output` | `ukcp18/land-rcm/datasets/rcp85/output` |
| Part of an output on a grid | `<output>/<IRI of the grid, relative>` | `ukcp18/land-rcm/datasets/rcp85/output/ukcp18/regional-splits/river` |
| **Processes** | | |
| Projects | `mips/<project>` | `mips/cordex-cmip5` |
| CMIP5 experiments | `mips/cmip5/experiments/<id>` | `mips/cmip5/experiments/rcp85` |
| Simulations, ensembles, CORDEX experiments and domains | `simulations/<id>` | `simulations/cordex.EUR-11.MPI-ESM-LR.rcp85.RCA4.v1.r1i1p1` |
| UKCP18 derivations | `derivations/<id>` | `derivations/ukcp18.prob.rcp85.gwl2.0` |
| UKCP18 processings of other sources | `ukcp18/<collection>/processing/<id>` | `ukcp18/land-gcm/processing/rcp26.18` |
| **Models, agents, scenarios** | | |
| Models | `models/<name>` | `models/HadGEM2-ES` |
| Organizations, people | `organizations/<id>`, `person/<name>` | `organizations/MOHC` |
| Scenarios | `scenarios/<family>/<id>` | `scenarios/RCP/RCP8.5` |
| Global warming levels | `GWLs/GWL<level>` | `GWLs/GWL1.5` |
| **Space and time** | | |
| Dimensions | `dimensions/<dimension>` | `dimensions/time`, `dimensions/geodetic` |
| Reference frames | `dimensions/<dimension>/reference-frames/<frame>[/<pole>]` | `dimensions/geodetic/reference-frames/rotated-WGS84/-162.0,39.25` |
| Points, regions | `<frame>/points/<lon>,<lat>`, `<frame>/regions/rectangle/<lon>,<lat>:<lon>,<lat>`, `dimensions/geodetic/all` | `dimensions/geodetic/reference-frames/WGS84/points/-162.0,39.25` |
| Time intervals | `dimensions/time/reference-frames/gregorian/regions/<start>-<end>` | `.../regions/1980-12-01T00:00:00Z-2080-12-01T00:00:00Z` |
| Quantizations of time | `.../gregorian/quantizations/<type>/<durations>` | `.../quantizations/regular/P1M` |
| Temporal grids | `<time interval>/quantized/<type>/<durations>` | `.../regions/<start>-<end>/quantized/regular/P1M` |
| Specializations | `<region or grid>/specialization` | `cordex/grids/EUR-11/specialization` |
| CORDEX domains and grids | `cordex/domains/<area>`, `cordex/grids/<domain>/ds` | `cordex/grids/EUR-11/ds` |
| Quantizations of the CORDEX grids | `dimensions/geodetic/quantizations/regular-angle/<degrees>` | `.../regular-angle/0.11` |
| Grid of a CMIP5 simulation | `simulations/<id>/geodetic-grid` | |
| UKCP18 grids | `dimensions/geodetic/reference-frames/OSGB36/grids/<n>km`, `ukcp18/grids/<name>`, `ukcp18/regional-splits/<kind>` | `ukcp18/grids/N216` |
| Quantizations of the UKCP18 grids | `geodeticgrid/km/<n>`, `ukcp18/grids/rotated-WGS84/2.2km/discretization`, with resolution `value/m/<n>` | `geodeticgrid/km/12` |
| **Controlled vocabularies** | | |
| Hazard types | `hazard-types/<Name in camel case>` | `hazard-types/CoastalErosion` |
| Operations, their roles, methods | `wf/ops/<Name>`, `wf/ops/<Name>/associated-data`, `wf/methods/<Name>` | `wf/ops/AddCaseTitle` |
| Schemes and their values | `wf/schemes/<Scheme>[/<value>]`, `mohc/sectors[/<name>]`, `<scheme of indices>` | `wf/schemes/RiskRating/high` |
| **Named graphs** | `<source>[/<part>]`, the namespace itself for the common entities | `cmip5/datasets`, `cordex/cvs`, `ukcp18` |

### Variations and open cases

- **Top-level names.** Most resources are under a plural name for their kind (`datasets`, `simulations`, `models`,
  `organizations`, `scenarios`), but: `person` is singular; `GWLs` is in upper case; `unitsofmeasure` and
  `geodeticgrid` are written without separator while `hazard-types` has one; the schemes of the MOHC indices
  (`Climate-ADAPT`, `Copernicus-CCS`, `ETCCDI`, `UK-CRI`) are directly under the namespace; `value/m/<n>` and
  `geodeticgrid/km/<n>` are the only resources under `value` and `geodeticgrid`.
- **By kind or by source.** The CMIP5 and CORDEX-CMIP5 resources are under their kind (`datasets/cmip5...`,
  `simulations/cordex...`, with the source as prefix of the id), while most UKCP18 resources are under their source
  (`ukcp18/datasets/...`, `ukcp18/<collection>/datasets/...`, `ukcp18/<collection>/processing/...`), but for its
  simulations and derivations (`simulations/ukcp18...`, `derivations/ukcp18...`). The same for the vocabularies:
  `climdex/...`, `mohc/sectors`, `cordex/domains` by source, `hazard-types`, `wf/...` by kind.
- **Outputs.** The output of a process has four forms: an id under `datasets` (`datasets/<simulation id>.<product>`),
  `<IRI of the process>/output` (UKCP18 simulations and derivations, projects), `datasets/cmip5.<experiment>/output`
  (which is not under the IRI of the experiment, `mips/cmip5/experiments/<experiment>`), and
  `ukcp18/<collection>/datasets/<scenario>/output`.
- **Experiments.** The CMIP5 experiments are under their project (`mips/cmip5/experiments/<id>`), the CORDEX ones
  under `simulations` (`simulations/cordex.<domain>.<experiment>`), as the CORDEX domains (typed only `top:Action`).
- **File extension.** The UKCP18 datasets have the file name with `.nc` in the IRI (not in the label); the land-prob
  datasets of the scenario `a1b` are renamed to `sres-a1b`.
- **Local names from text.** Where there is no id in the source, the local name is made from the name: in camel case
  (`hazard-types/CoastalErosion`, `wf/ops/AddCaseTitle`, the MOHC indices), or as it is, percent-encoded
  (`climdex/sectors/Agriculture%20and%20Food%20Security`, `mohc/sectors/Marine%20Ecosystems`). Parentheses and other
  punctuation of the names are kept: encoded in the hazard types and the methods
  (`wf/methods/AiMethods%28experimental%29`), not encoded in the MOHC indices
  (`Copernicus-CCS/indices/ConsecutiveFrostDays(cfd)`, `UK-CRI/indices/12-monthRiverDrought(extreme)`).
- **Encoded separators.** The units with a slash are encoded in one segment (`unitsofmeasure/m3%2Fm3`,
  `variables/ukcp/pr/mm%2Fday`), which some servers and clients decode or reject.
- **Punctuation in the local names.** Coordinates and intervals use `,` and `:` (`points/-162.0,39.25`,
  `regions/rectangle/<lon>,<lat>:<lon>,<lat>`, `regions/<start>-<end>` with the colons of the times); the pole of a
  rotated frame is a segment of coordinates (`rotated-WGS84/<lon>,<lat>`).
- **Collections and members in the same namespace.** `variables/cordex/<name>` is a variable and
  `variables/cordex/<model>` the collection of the variables of a model, whose variables are
  `variables/cordex/<model>/<name>/<units>`: a variable and a model with the same name would collide. Likewise the
  previous MIP variables, `variables/mip/<era>/<name>`, and the current ones, `variables/mip/<name>` (an era is not
  a variable name).
- **Variants of a variable.** The qualifiers of the UKCP18 variables are segments in a fixed order but of different
  kinds at the same level (`variables/ukcp/tas/degC`, units; `variables/ukcp/tasAnom/1981-2000`, baseline;
  `variables/ukcp/tasmax/rp20`, return period).
- **IRIs embedding IRIs.** The part of an output on a grid appends the relative IRI of the grid to that of the
  output (`.../output/dimensions/geodetic/reference-frames/OSGB36/grids/60km`), giving long IRIs whose inner
  segments are not resources.
- **Grids.** The grids are under the dimension and reference frame (`.../OSGB36/grids/12km`), under their source
  (`cordex/grids/<id>/ds`, `ukcp18/grids/N216`) or under a simulation (`simulations/<id>/geodetic-grid`); their
  quantizations under the dimension (`dimensions/geodetic/quantizations/regular-angle/0.11`), under the grid
  (`ukcp18/grids/rotated-WGS84/2.2km/discretization`) or on their own (`geodeticgrid/km/12`).
- **Graphs and resources with the same IRI.** `variables` and `indices` are both a named graph and the collection it
  contains; the graph of the common entities is the namespace without the final slash; the ontologies are in the
  graphs named as themselves.
- **Fixed in this review.** `dimensions/geodetic-lat/reference-frames/WGS8`, a typo in `common-spacetime.ttl`, is now
  `.../WGS84`; the temporal grids made by the consolidation use the scheme of the mappings
  (`<time interval>/quantized/...`).
