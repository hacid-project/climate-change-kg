# Provenance of a build of the knowledge graph, as JSON-LD (PROV-O, DCAT,
# Dublin Core terms): the build itself, an activity using the workflow at its
# commit, and the versions of the sources given by the configuration of the
# workflow (config/config.yaml, config/cmor-tables-eras.json), completing their
# descriptions in kg.ttl; with the public SPARQL endpoint, the website and the
# record of the dumps of the KG, if the configuration has them (metadata).
#
# Without input; arguments:
#   $config  the configuration of the workflow
#   $commit  the commit of the workflow
#   $date    the date and time of the build (xsd:dateTime)

# A value of the configuration that is given (not missing nor empty)
def present: select(. != null and . != "");

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
    "foaf": "http://xmlns.com/foaf/0.1/",
    "sd": "http://www.w3.org/ns/sparql-service-description#",
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
    # The public SPARQL endpoint: of the KG as a VoID dataset, and as a DCAT
    # data service serving it
    ($config.metadata.sparql_endpoint | present | (
      {"@id": "kg", "void:sparqlEndpoint": {"@id": .}},
      {
        "@id": "kg/services/sparql",
        "@type": ["dcat:DataService", "sd:Service"],
        "dcterms:title": {"@language": "en", "@value": "SPARQL endpoint of the HACID climate services knowledge graph"},
        "dcat:endpointURL": {"@id": .},
        "sd:endpoint": {"@id": .},
        "dcterms:conformsTo": {"@id": "https://www.w3.org/TR/sparql11-protocol/"},
        "dcat:servesDataset": {"@id": "kg"}
      }
    )),
    # The website documenting the KG: its landing page
    ($config.metadata.website_url | present | {
      "@id": "kg",
      "dcat:landingPage": {"@id": .},
      "foaf:homepage": {"@id": .}
    }),
    # The record of the dumps of the KG (a DOI): where the distribution is
    # accessed from, not the URL of a file (so neither dcat:downloadURL nor
    # void:dataDump)
    ($config.metadata.dumps_figshare_url | present | {
      "@id": "kg/distributions/nquads",
      "dcat:accessURL": {"@id": .},
      "dcterms:identifier": (select(startswith("https://doi.org/")) | ltrimstr("https://doi.org/"))
    }),
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
