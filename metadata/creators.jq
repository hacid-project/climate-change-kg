# The creators of the knowledge graph, from metadata/record.yaml (read with yq,
# the YAML front end of jq), as JSON-LD: dcterms:creator of the KG, each a
# foaf:Person named "Given Family", with a link to its ORCID record. The IRI of a
# person is person/<given>-<family>, lowercase, as in data-sources/people.ttl.

def given: split(", ") | .[1:] | join(", ");
def family: split(", ") | .[0];
def slug: ascii_downcase | gsub("[^a-z0-9]+"; "-") | ltrimstr("-") | rtrimstr("-");

[.creators[] | {
  "@id": "person/\("\(.name | given) \(.name | family)" | slug)",
  "@type": ["foaf:Agent", "foaf:Person"],
  "foaf:name": "\(.name | given) \(.name | family)"
} + (if .orcid then {"rdfs:seeAlso": {"@id": "https://orcid.org/\(.orcid)"}} else {} end)] as $creators
| "https://w3id.org/climate-change-kg" as $kg  # the KG as a dataset (see kg.ttl)
| {
  "@context": {
    "@base": "https://w3id.org/climate-change-kg/data/",
    "dcterms": "http://purl.org/dc/terms/",
    "foaf": "http://xmlns.com/foaf/0.1/",
    "rdfs": "http://www.w3.org/2000/01/rdf-schema#"
  },
  "@graph": [
    {"@id": $kg, "dcterms:creator": [$creators[] | {"@id": ."@id"}]},
    $creators[]
  ]
}
