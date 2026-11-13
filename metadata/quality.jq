# Results of the validation of the knowledge graph with its SHACL shapes, as
# JSON-LD (W3C Data Quality Vocabulary): a quality measurement for each
# severity, with the number of validation results, for the metrics defined in
# kg.ttl.
#
# Input: the summary of the validation report (kg/validation/summary.json, the
# SPARQL results of shapes/queries/summary.rq).

[.results.bindings[] | {severity: (.severity.value | sub(".*#"; "")), results: (.results.value | tonumber)}] as $summary
| {
  "@context": {
    "@base": "https://w3id.org/climate-change-kg/data/",
    "dqv": "http://www.w3.org/ns/dqv#",
    "xsd": "http://www.w3.org/2001/XMLSchema#"
  },
  "@graph": [
    {Violation: "violations", Warning: "warnings", Info: "infos"}
    | to_entries[]
    | .key as $severity
    | {
      "@id": "kg/quality/measurements/\(.value)",
      "@type": "dqv:QualityMeasurement",
      "dqv:computedOn": {"@id": "kg"},
      "dqv:isMeasurementOf": {"@id": "kg/quality/\(.value)"},
      "dqv:value": {
        "@type": "xsd:integer",
        "@value": ([$summary[] | select(.severity == $severity) | .results] | add // 0 | tostring)
      }
    }
  ]
}
