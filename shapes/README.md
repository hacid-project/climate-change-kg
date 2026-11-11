# SHACL shapes of the climate services KG

The shapes in this directory state what the consolidated KG is expected to look like: which properties the resources
of each kind have, how many, and what they point to. They are checked by the workflow (`snakemake --cores 4 validate`,
`workflow/rules/validate.smk`) on the KG after the consolidation.

## Running the validation

```bash
snakemake --cores 4 validate
```

The Jena command-line tools (`shacl`, `arq`, `riot`, `tdb2.tdbquery`) must be on the `PATH`, as for the consolidation.
The steps are:

1. `validate_shapes`: all the `shapes/*.ttl` are merged in `kg/validation/shapes.ttl` (which also checks their
   syntax);
2. `validate_data`: the data graph is extracted from the TDB2 dataset (`queries/data.rq`) as the union of the named
   graphs, without the graph of the metadata of the KG (validated on its own, `metadata/shapes.ttl`). A shape sees a
   resource with what every source says about it, together with the ontologies: `sh:class` and `sh:targetClass`
   follow the `rdfs:subClassOf` of the ontologies, so no inference is needed;
3. `validate_shacl`: `shacl validate` writes the validation report, `kg/validation/report.ttl` (about 7 minutes and
   10 GB of memory for the 5.7 million triples of the KG);
4. `validate_summary`: the report is summarised by severity, shape and message (`queries/summary.rq`), with the number
   of results and one focus node as example, in `kg/validation/summary.tsv` (to read) and `summary.json` (SPARQL
   results, for jq);
5. `validate_check`: the rule fails, listing them, if there are results of the severities of `config/config.yaml`
   (`validate.fail_on`, by default `Violation`).

The report and its summary are written whatever the results: the consolidation (`snakemake consolidate`) does not
depend on the check, only on the summary, whose numbers go in the metadata of the KG (`metadata/quality.jq`). To make
the validation a gate of the export, build the two targets together (`snakemake --cores 4 validate consolidate`).

To look at the results of a shape in the report:

```bash
arq --data kg/validation/report.ttl \
    'PREFIX sh: <http://www.w3.org/ns/shacl#>
     SELECT ?focusNode ?value ?message WHERE {
       ?result sh:sourceShape <https://w3id.org/hacid/data/cs/shapes/Variable-unitRequired> ;
               sh:focusNode ?focusNode .
       OPTIONAL { ?result sh:value ?value }
       OPTIONAL { ?result sh:resultMessage ?message }
     }'
```

## Severities

| Severity | Meaning | Example |
| --- | --- | --- |
| `sh:Violation` | The KG contradicts its model: a wrong mapping, a dangling reference, a term that no ontology declares. It should be fixed (in the mapping, the source data or the ontology) | an untyped resource, a dataset with two variables |
| `sh:Warning` | The KG is incomplete or inconsistent in a way that the sources may explain. It should be reviewed, and either fixed or accepted | a model without maintainer, an experiment without simulations |
| `sh:Info` | A convention that is not followed uniformly. It is reported once per class or property, with the number of cases, not once per resource | the instances of a class with labels with and without a language tag |

## Shapes

Each node shape has a label and a description (`rdfs:label`, `rdfs:comment`), and each of its property shapes an IRI
(`shape:<Node shape>-<aspect>`) and a message, so that the results of the report can be traced to the constraint
(`sh:sourceShape`) and grouped by it. The namespace of the shapes is `https://w3id.org/hacid/data/cs/shapes/`.

| File | Node shapes | What they check |
| --- | --- | --- |
| `generic.ttl` | `Resource`, `Class`, `Property` | Every resource of the KG is typed; every class and property used is declared by an ontology loaded in the KG |
| | `PropertyDatatype` | The literals of a datatype property have the datatype of its `rdfs:range` (one result per property). The domains and ranges of the object properties are not checked: the published KG is served with RDFS inference, which gives their types to the subjects and objects |
| | `LabelLanguage` | The labels of the instances of a class are all with or all without a language tag (one result per class) |
| `variables.ttl` | `Variable` | The variables of the catalogues (CF, MIP, local variables, indices): label, unit of measure, collection, links to other variables |
| | `MIPVariable`, `Anomaly`, `DistributionRepresentation` | Acronym and CF variable of a MIP variable; variable and baseline of an anomaly; variable of a distribution representation |
| | `UnitOfMeasure`, `Collection`, `Membership` | One label per unit; labels and components of the collections; what has members is a collection |
| `spacetime.ttl` | `TemporalRegion`, `GeodeticRegion`, `GeodeticPoint` | Start before end, as `xsd:dateTime`; geometries as WKT, with closed polygons |
| | `Grid`, `Quantization`, `PeriodicBinning`, `VariableSpecialization` | What a grid is based on, its bounding region and quantization; resolutions and periods; region and dimension of a specialization |
| `datasets.ttl` | `Dataset`, `Projection` | Components, variables, grids and specializations of a dataset; no unattached dataset; label, scenario and global warming level of a projection |
| | `VariableDataset`, `EnsembleProjection`, `ScenarioBasedProjection`, `ScenarioReference`, `GlobalWarmingLevelBasedProjection`, `DistributionDataset` | A dataset of a variable has a grid; an ensemble has components; a projection is scenario based if and only if it refers to a scenario (so not the historical ones), and likewise for a global warming level; a probabilistic dataset has the representation of its variable |
| `simulations.ttl` | `DataGeneratingProcess`, `ScenarioConsistency` | Label, inputs, outputs and components of any process; a process and its output, components and driving simulation agree on the scenario |
| | `SingleSimulation`, `EnsembleSimulation`, `ClimateSimulation`, `GlobalClimateSimulation`, `DynamicalDownscaling`, `DownscalingRun`, `ProjectionTransformation` | The model of each kind of simulation, its components and the kind of its outputs; the driving simulation of a downscaling; inputs and output of a transformation |
| | `ClimateModel`, `Organization`, `EmissionScenario`, `GlobalWarmingLevel` | Labels, maintainers, acronyms, values |
| `vocabularies.ttl` | `HazardType`, `Operation`, `InformationRole`, `Method`, `Concept`, `ConceptScheme`, `Classification`, `IndexAggregation` | The controlled vocabularies: labels, descriptions, indicators, roles, schemes, the time aggregations of the indices |

The shapes use SHACL Core, SPARQL-based constraints (`sh:sparql`, SHACL-SPARQL) where a check compares several
resources or is reported in aggregate, and SPARQL-based targets (`sh:SPARQLTarget`, SHACL Advanced Features) where the
focus nodes are not the instances of a class or the subjects of a property (e.g. the variables that are neither datasets
nor dimensional spaces, which in the data ontology are variables too). Both are supported by Jena; another validator
needs SHACL-SPARQL and SHACL-AF targets.

## Writing a shape

- A shape describes the KG as it should be, not as it is: when the validation reports a result, either the KG or the
  shape is wrong, and the decision (with its reason) belongs in the `DECISIONS.md` of the source or in the description
  of the shape.
- Target a class (`sh:targetClass`, with its subclasses) or the subjects or objects of a property; use a SPARQL-based
  target only when neither identifies the focus nodes.
- Give each property shape an IRI and a `sh:message`, and choose its severity as above. A constraint with thousands of
  expected results is better written as a SPARQL-based constraint grouping them (see `shape:LabelLanguage`).
- A constraint that needs a required value and a constraint on the values present are better kept apart (e.g.
  `shape:Variable-unit`, a violation if the unit is not a unit, and `shape:Variable-unitRequired`, a warning if there is
  none), so that each has its severity.
