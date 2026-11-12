# Mapping of the CMIP5 institutions (data/institutions-esgf.json: [{id,
# acronym, description, models}]) to JSON-LD: the organizations, with their id
# as acronym (as in the datasets: ESGF also has it in another case, e.g. CCCma)
# and their name, and their models (global climate models, named as in the
# datasets, cmip5_model_name), which they maintain. All the CMIP5 models of the
# ESGF configuration are given, also those without datasets in the KG: other
# sources refer to them (e.g. as driving models).

include "esgf";
include "cmip5-datasets";

{
    "@context": {
        rdfs: "http://www.w3.org/2000/01/rdf-schema#",
        top: "https://w3id.org/hacid/onto/top-level/",
        ccso: "https://w3id.org/hacid/onto/ccso/",
        label: {"@id": "rdfs:label", "@language": "en"},
        name: "rdfs:label",
        acronym: "top:acronym",
        isMaintainedBy: {"@id": "ccso:isMaintainedBy", "@type": "@id"}
    },
    "@graph": [
        .[] |
        (.id | cmip5_institute_iri) as $institute |
        {
            "@id": $institute,
            "@type": "top:Organization",
            acronym: .id,
            label: .description
        },
        (
            .models[]? | cmip5_model_name |
            {
                "@id": cmip5_model_iri,
                "@type": "ccso:GlobalClimateModel",
                name: .,
                isMaintainedBy: $institute
            }
        )
    ]
}
