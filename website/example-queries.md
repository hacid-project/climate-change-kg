---
title: Example Queries
layout: page
nav_order: 5
---

# Example Queries

The following are some example SPARQL queries that can be performed against the Climate Change Knowledge Graph, organized by types of information.
They can be run on the [SPARQL endpoint](data-access#query-the-sparql-endpoint).

Each query answers one of the [competency questions](competency-questions) that guided the design of the knowledge graph, and thus also serves as its validation.
{% for category in site.data.cqs.categories %}
{%- assign has_queries = false -%}
{%- for cq in site.data.cqs.competency_questions -%}
{%- if cq.category == category.id and cq.queries -%}{%- assign has_queries = true -%}{%- endif -%}
{%- endfor -%}
{%- if has_queries %}

## {{ category.title }}
{% for cq in site.data.cqs.competency_questions -%}
{%- if cq.category == category.id -%}
{%- for query in cq.queries %}

### {{ query.title }}
{: #{{ query.id }} }

*Answers [{{ cq.id }}](competency-questions#{{ cq.id | downcase }}): {{ cq.question }}*

{{ query.description }}

```sparql
{{ query.query }}```
{%- endfor -%}
{%- endif -%}
{%- endfor -%}
{%- endif -%}
{% endfor %}
