# w3id.org redirects (draft, not yet submitted)

The KG moved from `https://w3id.org/hacid/data/cs/` to its own namespace, `https://w3id.org/cckg/`:

| | Old | New |
|:--|:--|:--|
| Resources and named graphs | `https://w3id.org/hacid/data/cs/...` | `https://w3id.org/cckg/data/...` |
| Root named graph | `https://w3id.org/hacid/data/cs` | `https://w3id.org/cckg/data` |
| Dataset (and metadata graph) | `https://w3id.org/hacid/data/cs/kg` | `https://w3id.org/cckg/data/kg` |
| SPARQL endpoint | `https://w3id.org/hacid/cs/sparql` | `https://w3id.org/cckg/sparql` |
| Website | `https://hacid-project.github.io/cckg/` | `https://w3id.org/cckg` |

The ontologies stay at `https://w3id.org/hacid/onto/{top-level,data,ccso}`.

To make the new IRIs resolve, with a pull request to [perma-id/w3id.org](https://github.com/perma-id/w3id.org):

1. check that the directory `cckg/` is not taken;
2. add `cckg/.htaccess` and `cckg/README.md` from this directory, after replacing the two placeholders
   (`SPARQL_ENDPOINT_URL`, `LINKED_DATA_BASE_URL`) with the targets of the present rules of `hacid/.htaccess`;
3. add the rules of `hacid-additions.htaccess` to `hacid/.htaccess`, before its rules on `data/` and `cs/sparql`, so
   that the old IRIs redirect to the new ones.

The linked data front end and the SPARQL endpoint have to serve a build of the KG with the new IRIs before (or
together with) the redirects: until then the new IRIs have no description.
