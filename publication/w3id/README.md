# w3id.org redirects

The KG moved from `https://w3id.org/hacid/data/cs/` to its own namespace, `https://w3id.org/climate-change-kg/`:

| | Old | New |
|:--|:--|:--|
| Resources and named graphs | `https://w3id.org/hacid/data/cs/...` | `https://w3id.org/climate-change-kg/data/...` |
| Root named graph | `https://w3id.org/hacid/data/cs` | `https://w3id.org/climate-change-kg/data` |
| Dataset (and metadata graph) | `https://w3id.org/hacid/data/cs/kg` | `https://w3id.org/climate-change-kg/data/kg` |
| SPARQL endpoint | `https://w3id.org/hacid/cs/sparql` | `https://w3id.org/climate-change-kg/sparql` |
| Website | `https://hacid-project.github.io/cckg/` | `https://w3id.org/climate-change-kg` |

The ontologies stay at `https://w3id.org/hacid/onto/{top-level,data,ccso}`.

To make the new IRIs resolvThe redirect rules are prepared (not yet submitted to [perma-id/w3id.org](https://github.com/perma-id/w3id.org)) in
two branches of the fork [miguel76/w3id.org](https://github.com/miguel76/w3id.org), one per pull request:

1. `climate-change-kg`: the new identifier, `ids/climate-change-kg/` (resources to the linked data front end, the
   endpoint, anything else to the website);
2. `hacid-climate-services-to-climate-change-kg` (on top of the first): `/hacid/data/cs/...` redirects to
   `/climate-change-kg/data/...`; the other HACID redirects, `/hacid/cs/sparql` included, are unchanged.

The linked data front end and the SPARQL endpoint have to serve a build of the KG with the new IRIs for the new IRIs
to be described.
