# Provenance of a build of the knowledge graph, as JSON-LD (PROV-O, DCAT,
# Dublin Core terms): the build itself, an activity using the workflow at its
# commit, and the versions of the sources given by the configuration of the
# workflow (config/config.yaml, config/cmor-tables-eras.json), completing their
# descriptions in kg.ttl; with the public SPARQL endpoint and the published
# dump of the KG, if the configuration has them (metadata).
#
# Without input; arguments:
#   $config  the configuration of the workflow
#   $commit  the commit of the workflow
#   $date    the date and time of the build (xsd:dateTime)

# The page of a git repository (its URL without .git)
def repository: sub("\\.git$"; "");

# A source in a git repository at a ref
def git_source($id; $repo; $ref):
  {
    "@id": $id,
    "dcat:landingPage": {"@id": ($repo | repository)},
    "prov:atLocation": {"@id": "\($repo | repository)/tree/\($ref)"},
    "dcat:version": $ref
  };

"https://github.com/hacid-project/climate-services-kg" as $workflow
| {
  "@context": {
    "@base": "https://w3id.org/hacid/data/cs/",
    "dcterms": "http://purl.org/dc/terms/",
    "dcat": "http://www.w3.org/ns/dcat#",
    "void": "http://rdfs.org/ns/void#",
    "prov": "http://www.w3.org/ns/prov#",
    "xsd": "http://www.w3.org/2001/XMLSchema#"
  },
  "@graph": [
    {
      "@id": "kg",
      "dcterms:modified": {"@type": "xsd:dateTime", "@value": $date},
      "dcat:version": $commit[:7],
      "prov:wasGeneratedBy": {
        "@id": "kg/builds/\($commit[:7])",
        "@type": "prov:Activity",
        "prov:endedAtTime": {"@type": "xsd:dateTime", "@value": $date},
        "prov:used": {
          "@id": "\($workflow)/tree/\($commit)",
          "@type": ["prov:Entity", "prov:Plan"],
          "dcterms:title": {"@language": "en", "@value": "Workflow of the HACID climate services knowledge graph"},
          "dcat:landingPage": {"@id": $workflow},
          "dcat:version": $commit
        }
      }
    },
    ($config.metadata.sparql_endpoint | select(. != "") | {"@id": "kg", "void:sparqlEndpoint": {"@id": .}}),
    ($config.metadata.download_url | select(. != "") | (
      {"@id": "kg", "void:dataDump": {"@id": .}},
      {"@id": "kg/distributions/nquads", "dcat:downloadURL": {"@id": .}}
    )),
    git_source("sources/ontologies"; $config.ontologies.repo; $config.ontologies.version),
    git_source("sources/esgf-config"; $config.cmip5_cvs.esgf_config_repo; $config.cmip5_cvs.esgf_config_version),
    git_source("sources/cordex-domains"; $config.cordex_domains.repo; $config.cordex_domains.version),
    git_source("sources/cordex-rcms"; $config.cordex_cmip5_cvs.repo; $config.cordex_cmip5_cvs.version),
    ($config.cf_standard_names | {
      "@id": "sources/cf-standard-names",
      "dcat:landingPage": {"@id": .url},
      "prov:atLocation": {"@id": "\(.url)/\(.version)/src/cf-standard-name-table.xml"},
      "dcat:version": (.version | tostring)
    }),
    # The CMOR tables of each era: at its version, if the era has one (the
    # editions of the others are given by the mapping to the MIP variables)
    ($config.eras[] | {
      "@id": "sources/cmor-tables/\(.era)",
      "dcat:landingPage": {"@id": (.repo | repository)}
    } + (
      if .version then {
        "prov:atLocation": {"@id": "\(.repo | repository)/tree/\(.version)"},
        "dcat:version": .version
      } else {} end
    ))
  ]
}
