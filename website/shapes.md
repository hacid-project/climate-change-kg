---
title: SHACL Shapes
layout: page
nav_order: 7
permalink: /shapes/
---

# SHACL Shapes

The knowledge graph is validated with [SHACL](https://www.w3.org/TR/shacl/) shapes, which state which properties the
resources of each kind have, how many, and what they point to. Each shape has an IRI in the namespace

`https://w3id.org/climate-change-kg/shapes/`

for example `https://w3id.org/climate-change-kg/shapes/Resource`. The dataset description of the KG points to this
namespace with `dcterms:conformsTo`.

## Download

All the shapes in one file, [shapes.ttl](shapes.ttl) (Turtle), or by topic:

| File | Checks |
| --- | --- |
| [generic.ttl](generic.ttl) | every resource is typed; every class and property used is declared; labels |
| [vocabularies.ttl](vocabularies.ttl) | controlled vocabularies |
| [variables.ttl](variables.ttl) | climate variables |
| [datasets.ttl](datasets.ttl) | datasets |
| [simulations.ttl](simulations.ttl) | models and simulations |
| [spacetime.ttl](spacetime.ttl) | spatial and temporal coverage |

The shapes use SPARQL-based targets and constraints (SHACL Advanced Features, SHACL-SPARQL), so a validator that
supports them is needed, for example the `shacl` tool of [Apache Jena](https://jena.apache.org/). The shapes, their
severities and how to read a validation report are documented in the
[repository](https://github.com/hacid-project/climate-services-kg/tree/main/shapes).

```bash
curl -L -H 'Accept: text/turtle' https://w3id.org/climate-change-kg/shapes -o shapes.ttl
shacl validate --shapes shapes.ttl --data data.ttl
```

The shapes are published under the [CC BY 4.0 license](https://creativecommons.org/licenses/by/4.0/).
