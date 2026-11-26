# w3id.org redirects

The KG moved from `https://w3id.org/hacid/data/cs/` to its own namespace, `https://w3id.org/climate-change-kg/`:

| | Old | New |
|:--|:--|:--|
| Resources and named graphs | `https://w3id.org/hacid/data/cs/...` | `https://w3id.org/climate-change-kg/data/...` |
| Root named graph | `https://w3id.org/hacid/data/cs` | `https://w3id.org/climate-change-kg/data` |
| Dataset (the KG itself) | `https://w3id.org/hacid/data/cs/kg` | `https://w3id.org/climate-change-kg` |
| Metadata graph (the description of the KG) | `https://w3id.org/hacid/data/cs/kg` | `https://w3id.org/climate-change-kg/data/kg` |
| SPARQL endpoint | `https://w3id.org/hacid/cs/sparql` | `https://w3id.org/climate-change-kg/sparql` |
| Website | `https://hacid-project.github.io/cckg/` | `https://w3id.org/climate-change-kg` |

The ontologies stay at `https://w3id.org/hacid/onto/{top-level,data,ccso}`.

The new identifier, `ids/climate-change-kg/` (resources to the linked data front end, the endpoint, anything else to
the website), is merged in [perma-id/w3id.org](https://github.com/perma-id/w3id.org). The redirect rules still to
submit are prepared in branches of the fork [miguel76/w3id.org](https://github.com/miguel76/w3id.org), one per pull
request:

1. `hacid-climate-services-to-climate-change-kg`: `/hacid/data/cs/...` redirects to `/climate-change-kg/data/...`; the
   other HACID redirects, `/hacid/cs/sparql` included, are unchanged (this branch has to be rebased on the updated
   `master` of the fork);
2. `climate-change-kg-shapes-redirects`: the redirects of the shapes and the content negotiation on the root, for
   the KG as a dataset, both below (one pull request).

The linked data front end and the SPARQL endpoint have to serve a build of the KG with the new IRIs for the new IRIs
to be described.

## Shapes

The SHACL shapes of the KG (`shapes/`) are published at `https://w3id.org/climate-change-kg/shapes` (the shapes are in
the namespace `https://w3id.org/climate-change-kg/shapes/`). The website workflow (`website/collect-shapes.sh`) copies
them, with the combined `shapes.ttl`, to the `shapes/` folder of the GitHub Pages site, next to the landing page
(`website/shapes.md`). The redirect rules, content negotiation between the Turtle file and the landing page, are in
the branch `climate-change-kg-shapes-redirects` of the fork (`ids/climate-change-kg/.htaccess`).

## The KG as a dataset

The KG itself, as a dataset (`dcat:Dataset`, `void:Dataset`), is the root `https://w3id.org/climate-change-kg`, as the
IRI of an ontology is the root of its namespace. Releases 1.0.0 and 1.1.0 named it `https://w3id.org/climate-change-kg/data/kg`,
which stays the name of the graph holding its description (`void:DatasetDescription`, `foaf:primaryTopic` the root), as
`void.ttl` of each release (see `metadata/kg.ttl`). The resources the description introduces (distributions, releases,
builds, partitions, quality measurements) are named under `.../data/kg/` and `.../data/kg#`, so the linked data front end
serves them.

The root redirects to the website (the rule for anything else). For the root to be the IRI of the KG, an RDF client asking
for it is to get the description instead: the rule below, before the rule for anything else, sends it to the SPARQL
endpoint, with a query returning the graph of the description (`CONSTRUCT`, in the format asked for). A browser still
gets the website, which is the landing page of the KG (`dcat:landingPage`).

```apache
# The knowledge graph itself, as a dataset (its IRI is the root): if RDF is
# requested, its description, the named graph .../data/kg, from the SPARQL
# endpoint (CONSTRUCT); otherwise (a browser) the documentation website, below.
# A literal % in the target is written \% (otherwise %N is a back-reference),
# and NE keeps it from being escaped again.
RewriteCond %{HTTP_ACCEPT} text/turtle [OR]
RewriteCond %{HTTP_ACCEPT} application/rdf\+xml [OR]
RewriteCond %{HTTP_ACCEPT} application/ld\+json [OR]
RewriteCond %{HTTP_ACCEPT} application/n-triples
RewriteRule ^$ https://keng.istc.cnr.it/climate-change-kg/sparql?query=CONSTRUCT+\%7B+\%3Fs+\%3Fp+\%3Fo+\%7D+WHERE+\%7B+GRAPH+\%3Chttps\%3A\%2F\%2Fw3id.org\%2Fclimate-change-kg\%2Fdata\%2Fkg\%3E+\%7B+\%3Fs+\%3Fp+\%3Fo+\%7D+\%7D [R=303,NE,L]
```

The rule is in the branch `climate-change-kg-shapes-redirects` (commit `6d63e3f`, with the shapes redirects squashed
in it, on `master` of perma-id/w3id.org at `f203688`), with the README of the identifier. It passes the checker of w3id.org (`tools/check`, no problems), and
was checked (2026-11-25) on Apache 2.4 (`tools/server`, with the Apache of the system):
with `Accept: text/turtle` (or `application/ld+json`), `https://w3id.org/climate-change-kg` (after the redirect to
`.../climate-change-kg/`) answers 303 to the query, decoded as
`CONSTRUCT { ?s ?p ?o } WHERE { GRAPH <https://w3id.org/climate-change-kg/data/kg> { ?s ?p ?o } }`; with the `Accept`
of a browser, or `*/*`, 302 to the website, as now; `data/kg` and `shapes` are unchanged. The query, sent to
`https://keng.istc.cnr.it/climate-change-kg/sparql` with `Accept: text/turtle`, returns the description in Turtle
(the current one, still with the KG named `.../data/kg` until the next release).

Until a release with the new IRI is served and the rule is merged, the root gives the website to everyone, and
`.../data/kg` is still described as the dataset by the release served.
