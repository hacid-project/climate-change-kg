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
#   $release (optional, --argjson) the release being made (rule release,
#            kg/release/<version>/commit.json): {version, doi, url, date,
#            concept_doi, files_url, previous: {version, doi} or null}. The KG
#            then has the version of the release (otherwise the short commit),
#            and the release is described as a version of it (DCAT 3)

# A value of the configuration that is given (not missing nor empty)
def present: select(. != null and . != "");

# The page of a git repository (its URL without .git)
def repository: sub("\\.git$"; "");

# The release, if any
($ARGS.named.release // null) as $release
|

# A source in a git repository at a ref
def git_source($id; $repo; $ref):
  {
    "@id": $id,
    "dcat:landingPage": {"@id": ($repo | repository)},
    "prov:atLocation": {"@id": "\($repo | repository)/tree/\($ref)"},
    "dcat:version": $ref
  };

"https://github.com/hacid-project/climate-change-kg" as $workflow
| {
  "@context": {
    "@base": "https://w3id.org/climate-change-kg/data/",
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
      "dcat:version": (if $release then $release.version else $commit[:7] end),
      "prov:wasGeneratedBy": {
        "@id": "kg/builds/\($commit[:7])",
        "@type": "prov:Activity",
        "prov:endedAtTime": {"@type": "xsd:dateTime", "@value": $date},
        "prov:used": {
          "@id": "\($workflow)/tree/\($commit)",
          "@type": ["prov:Entity", "prov:Plan"],
          "dcterms:title": {"@language": "en", "@value": "Workflow of the Climate Change Knowledge Graph"},
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
        "dcterms:title": {"@language": "en", "@value": "SPARQL endpoint of the Climate Change Knowledge Graph"},
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
    # The record of the releases of the KG (its concept DOI): where the distribution is
    # accessed from, not the URL of a file (so neither dcat:downloadURL nor
    # void:dataDump)
    ($config.metadata.dumps_record | present | {
      "@id": "kg/distributions/nquads",
      "dcat:accessURL": {"@id": .},
      "dcterms:identifier": (select(startswith("https://doi.org/")) | ltrimstr("https://doi.org/"))
    }),
    # The release: a version of the KG, with its DOI and its files on Zenodo
    ($release | values | (
      {"@id": "kg", "dcat:hasVersion": {"@id": "kg/releases/\(.version)"}},
      {
        "@id": "kg/releases/\(.version)",
        "@type": "dcat:Dataset",
        "dcterms:title": {"@language": "en", "@value": "Climate Change Knowledge Graph \(.version)"},
        "dcat:version": .version,
        "dcterms:identifier": .doi,
        "dcterms:issued": {"@type": "xsd:date", "@value": .date},
        "dcterms:isVersionOf": {"@id": "kg"},
        "foaf:page": {"@id": "https://doi.org/\(.doi)"},
        "dcat:distribution": {"@id": "kg/releases/\(.version)/distributions/nquads"}
      } + (.previous | values | {"dcat:previousVersion": {"@id": "kg/releases/\(.version)"}} // {}),
      {
        "@id": "kg/releases/\(.version)/distributions/nquads",
        "@type": "dcat:Distribution",
        "dcterms:title": {"@language": "en", "@value": "N-Quads dump of the Climate Change Knowledge Graph \(.version)"},
        "dcterms:format": {"@id": "http://www.w3.org/ns/formats/N-Quads"},
        "dcat:mediaType": {"@id": "https://www.iana.org/assignments/media-types/application/n-quads"},
        "dcat:compressFormat": {"@id": "https://www.iana.org/assignments/media-types/application/gzip"},
        "dcterms:license": {"@id": "https://creativecommons.org/licenses/by/4.0/"},
        "dcat:accessURL": {"@id": "https://doi.org/\(.doi)"},
        "dcat:downloadURL": {"@id": "\(.files_url)/kg.nq.gz?download=1"}
      },
      (.previous | values | {
        "@id": "kg/releases/\(.version)",
        "@type": "dcat:Dataset",
        "dcat:version": .version,
        "dcterms:identifier": .doi,
        "dcterms:isVersionOf": {"@id": "kg"},
        "foaf:page": {"@id": "https://doi.org/\(.doi)"}
      })
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
