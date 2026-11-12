{
    "@context": {
        rdfs: "http://www.w3.org/2000/01/rdf-schema#",
        top: "https://w3id.org/hacid/onto/top-level/",
        ccso: "https://w3id.org/hacid/onto/ccso/",
        label: "rdfs:label",
        label_en: {"@id": "rdfs:label", "@language": "en"},
        comment: {"@id": "rdfs:comment", "@language": "en"},
        acronym: "top:acronym",
        isMaintainedBy: {
            "@id": "ccso:isMaintainedBy",
            "@type": "@id"
        }
    },
    "@graph": [
        (.[] | {
            "@id": @uri "https://w3id.org/hacid/data/cs/models/\(.model_id)",
            "@type": "ccso:RegionalClimateModel",
            label: .model_id,
            isMaintainedBy: {
                "@id": @uri "https://w3id.org/hacid/data/cs/organizations/\(.institute_id)",
                "@type": "top:Organization",
                acronym: .institute_id,
                label_en: .institute_name
            }
        }),
        # The institutes of the datasets that are not in the list of the RCMs
        # (mapping/institute-names.json)
        (
            $institute_names[0] | to_entries[] | select(.value | type == "object") |
            {
                "@id": @uri "https://w3id.org/hacid/data/cs/organizations/\(.key)",
                "@type": "top:Organization",
                acronym: .key,
                label_en: .value.name
            }
        )
    ]
}
