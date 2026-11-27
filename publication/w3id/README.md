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

All the rules are merged in [perma-id/w3id.org](https://github.com/perma-id/w3id.org) (`ids/climate-change-kg/`, and
`ids/hacid/` for the old IRIs), from branches of the fork [miguel76/w3id.org](https://github.com/miguel76/w3id.org):

1. the new identifier (resources to the linked data front end, the endpoint, anything else to the website):
   [perma-id/w3id.org#7170](https://github.com/perma-id/w3id.org/pull/7170), merged 2026-11-13;
2. `/hacid/data/cs/...` redirecting to `/climate-change-kg/data/...` and `/hacid/cs/sparql` to the new endpoint:
   [perma-id/w3id.org#7202](https://github.com/perma-id/w3id.org/pull/7202), merged 2026-11-17;
3. the redirects of the shapes and the content negotiation on the root, for the KG as a dataset, both below:
   [perma-id/w3id.org#7320](https://github.com/perma-id/w3id.org/pull/7320), merged 2026-11-26.

The linked data front end and the SPARQL endpoint have to serve a build of the KG with the new IRIs for the new IRIs
to be described.

## Shapes

The SHACL shapes of the KG (`shapes/`) are published at `https://w3id.org/climate-change-kg/shapes` (the shapes are in
the namespace `https://w3id.org/climate-change-kg/shapes/`). The website workflow (`website/collect-shapes.sh`) copies
them, with the combined `shapes.ttl`, to the `shapes/` folder of the GitHub Pages site, next to the landing page
(`website/shapes.md`). The redirect rules, content negotiation between the Turtle file and the landing page, are in
`ids/climate-change-kg/.htaccess` of w3id.org (perma-id/w3id.org#7320).

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

The rule is live since perma-id/w3id.org#7320 (merged 2026-11-26). Checked on w3id.org on 2026-11-27, with release
1.2.0 served:

- `https://w3id.org/climate-change-kg` answers 301 to `.../climate-change-kg/` (Apache adds the slash). With
  `Accept: text/turtle`, `application/ld+json`, `application/rdf+xml` or `application/n-triples`,
  `.../climate-change-kg/` then answers 303 to the query, decoded as
  `CONSTRUCT { ?s ?p ?o } WHERE { GRAPH <https://w3id.org/climate-change-kg/data/kg> { ?s ?p ?o } }`, which returns
  200 in the format asked for: the description, with `<https://w3id.org/climate-change-kg>` as the dataset,
  `foaf:primaryTopic` of `.../data/kg`, and `dcat:hasCurrentVersion` the release 1.2.0. With the `Accept` of a
  browser, or `*/*`, it answers 302 to the website (200).
- `shapes` (303 to `shapes.ttl` for RDF, to the shapes page otherwise), `shapes/<topic>.ttl` (302), `data` (302 to
  the data access page), `data/...` (303 to the linked data front end), `sparql` (307, GET and POST answer) and any
  other path (302 to the website) work as before.
- The old IRIs (`/hacid/data/cs/...`, `/hacid/cs/sparql`) redirect to the new ones.
