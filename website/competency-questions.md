---
title: Competency Questions
layout: page
nav_order: 4
---

# Competency Questions

The Climate Change Knowledge Graph and its ontology network have been designed following the [eXtreme Design (XD)](https://ceur-ws.org/Vol-516/pap21.pdf) methodology, a test-driven approach to ontology design.
Requirements are expressed as *competency questions* (CQs): questions, in natural language, that the knowledge graph is expected to answer.
The CQs below have been elicited in dialogue with climate science and climate service experts throughout the design process, and the list is extended as new requirements arise.

Each CQ is validated by one or more SPARQL queries that answer it on the actual content of the knowledge graph, listed in the [example queries](example-queries).
Successfully writing such a query shows that the ontology can represent the information required by the CQ; running it and obtaining meaningful results shows that the knowledge graph actually contains it.
CQs marked as *not yet validated* express requirements that are planned but not yet covered by the published content.

{% assign cqs = site.data.cqs.competency_questions -%}
{% assign num_validated = 0 -%}
{% for cq in cqs -%}
{% if cq.queries -%}
{% assign num_validated = num_validated | plus: 1 -%}
{% endif -%}
{% endfor -%}
Currently, {{ num_validated }} of {{ cqs.size }} CQs are validated.

{% for category in site.data.cqs.categories %}
## {{ category.title }}

| ID | Competency question | Validated by |
|:---|:--------------------|:-------------|
{% for cq in cqs -%}
{% if cq.category == category.id -%}
| <a id="{{ cq.id | downcase }}"></a>**{{ cq.id }}** | **{{ cq.title }}.** {{ cq.question }} | {% if cq.queries %}{% for query in cq.queries %}[{{ query.title }}](example-queries#{{ query.id }}){% unless forloop.last %}, {% endunless %}{% endfor %}{% else %}*not yet validated*{% endif %} |
{% endif -%}
{% endfor %}
{% endfor %}
