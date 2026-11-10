PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ccso: <https://w3id.org/hacid/onto/ccso/>
PREFIX data: <https://w3id.org/hacid/onto/data/>
PREFIX top: <https://w3id.org/hacid/onto/top-level/> 
PREFIX dimension: <https://w3id.org/hacid/data/cs/dimensions/>
PREFIX time: <https://w3id.org/hacid/data/cs/dimensions/time/reference-frames/>

INSERT {
    GRAPH ?simulationGraph {
        ?simulationOutput
            data:dependsOnVariable ?simulationTemporalGrid;
            data:isSpecializedAccordingTo ?simulationTemporalSpecialization.
        ?simulationTemporalGrid a data:DimensionalSpace;
            data:basedOnDimensionalSpace time:gregorian;
            data:hasExactBoundingRegion ?simulationTemporalRegion;
            data:adoptsQuantization ?simulationQuantization.
        ?simulationTemporalSpecialization a data:VariableSpecialization;
            data:isSpecializationOn dimension:time;
            data:hasSelectedRegion ?simulationTemporalRegion.
        ?simulationTemporalRegion a data:TemporalRegion;
            rdfs:label ?simulationTemporalRegionLabel;
            rdfs:comment ?simulationTemporalRegionComment;
            data:hasStartDateTime ?simulationStartTime;
            data:hasEndDateTime ?simulationEndTime.
        ?simulationQuantization
#            a ?finestTemporalQuantizationType;
            a data:SimpleRegularBinning;
            data:hasResolutionValue ?minResolution.
#           data:hasPeriodValue ?minGridPeriod.
    }
}
WHERE {
    {
        SELECT
            ?simulationGraph ?simulationOutput
            (MIN(?startTime) AS ?simulationStartTime)
            (MAX(?endTime)AS ?simulationEndTime) 
#            (MAX(?quantizationTypeId) AS ?mostFineGrainedQuantizationTypeId)
            # The finest resolution: the durations are not ordered in SPARQL
            # (MIN gives an arbitrary one), so the minimum is taken on a key
            # that sorts as their approximate length in seconds. A quantization
            # without resolution (e.g. a periodic one) has the key "none",
            # which sorts last: MIN gives no value at all if the expression is
            # unbound for a solution of the group
            (MIN(COALESCE(?resolutionKey, "none")) AS ?minResolutionKey)
#            (MIN(?gridPeriod) AS ?minGridPeriod)
        WHERE {
	        ?simulation rdf:type/rdfs:subClassOf ccso:Simulation.
            GRAPH ?simulationGraph {
                ?simulation data:hasOutput ?simulationOutput
            }
            ?simulationOutput top:hasComponent+/data:dependsOnVariable ?temporalDS.
            ?temporalDS
                data:basedOnDimensionalSpace+ dimension:time;
                data:hasExactBoundingRegion [
                    data:hasStartDateTime ?startTime;
                    data:hasEndDateTime ?endTime
                ];
                data:adoptsQuantization ?quantization.
            ?quantization a ?quantizationType.
            OPTIONAL {
                ?quantization data:hasResolutionValue ?resolution.
                BIND(STR(?resolution) AS ?duration)
                BIND(
                    COALESCE(xsd:integer(REPLACE(?duration, "^P([0-9]+)Y.*$", "$1")), 0) * 31556952 +
                    COALESCE(xsd:integer(REPLACE(?duration, "^P([0-9]+Y)?([0-9]+)M.*$", "$2")), 0) * 2629746 +
                    COALESCE(xsd:integer(REPLACE(?duration, "^P([0-9]+Y)?([0-9]+M)?([0-9]+)D.*$", "$3")), 0) * 86400 +
                    COALESCE(xsd:integer(REPLACE(?duration, "^.*T([0-9]+)H.*$", "$1")), 0) * 3600 +
                    COALESCE(xsd:integer(REPLACE(?duration, "^.*T([0-9]+H)?([0-9]+)M.*$", "$2")), 0) * 60 +
                    COALESCE(xsd:integer(REPLACE(?duration, "^.*T([0-9]+H)?([0-9]+M)?([0-9]+)S$", "$3")), 0)
                    AS ?seconds
                )
                BIND(CONCAT(SUBSTR("000000000000", STRLEN(STR(?seconds)) + 1), STR(?seconds), " ", ?duration) AS ?resolutionKey)
            }.
#                OPTIONAL {?quantization data:hasPeriodValue ?gridPeriod}.
            VALUES (?quantizationType ?quantizationTypeId) {
                (data:SimpleRegularBinning 'regular')
                (data:SinglePeriodicBinning 'periodic')
                (data:RegularPeriodicBinning 'regular-periodic')
                (data:SingleBinBinning 'constant')
            }.
            FILTER NOT EXISTS {
                ?simulationOutput data:dependsOnVariable [
                    data:basedOnDimensionalSpace+ dimension:time;
                    data:hasExactBoundingRegion ?simulationTemporalRegion
                ]
            }
        }
        GROUP BY ?simulationGraph ?simulationOutput
    }
    BIND(IF(?minResolutionKey != "none", STRDT(STRAFTER(?minResolutionKey, " "), xsd:duration), ?none) AS ?minResolution)
    BIND(CONCAT(STR(?simulationStartTime), " ", STR(?simulationEndTime)) AS ?simInterval)
    BIND("(.*) (.*)" AS ?re)
    BIND(
        IRI(REPLACE(?simInterval, ?re,
            "https://w3id.org/hacid/data/cs/dimensions/time/reference-frames/gregorian/regions/$1-$2"
        )) AS ?simulationTemporalRegion
    ).
    BIND(
        STRLANG(REPLACE(?simInterval, ?re,
            "Time interval $1 - $2"
        ), "en") AS ?simulationTemporalRegionLabel
    ).
    BIND(
        STRLANG(REPLACE(?simInterval, ?re,
            "Time interval starting at date time $1 and ending at date time $2."
        ), "en") AS ?simulationTemporalRegionComment
    ).
    BIND(
        IRI(REPLACE(?simInterval, ?re,
            "https://w3id.org/hacid/data/cs/dimensions/time/reference-frames/gregorian/regions/$1-$2/specialization"
        )) AS ?simulationTemporalSpecialization
    ).
    # Without a resolution (no component with a regular temporal grid), the
    # output has only its temporal region and specialization: the grid and its
    # quantization are left unbound, and their triples are not inserted
    BIND(
        CONCAT(
#            ?mostFineGrainedQuantizationTypeId,
            'regular',
            CONCAT ('/', STR(?minResolution))
#            COALESCE(CONCAT ('/', STR(?minGridPeriod)), '')
        ) AS ?gridTypeId
    ).
    BIND(
        IRI(
            CONCAT(
                REPLACE(
                    ?simInterval, ?re,
                    "https://w3id.org/hacid/data/cs/dimensions/time/reference-frames/gregorian/regions/$1-$2/"
                ),
                ?gridTypeId
            )
        ) AS ?simulationTemporalGrid
    ).
    BIND(
        IRI(
            CONCAT(
                "https://w3id.org/hacid/data/cs/dimensions/time/reference-frames/gregorian/quantizations/",
                ?gridTypeId
            )
        ) AS ?simulationQuantization
    ).
    # VALUES (?finestTemporalQuantizationType ?mostFineGrainedQuantizationTypeId) {
    #     (data:RollingRegularGrid 'rolling')
    #     (data:PeriodicRegularGrid 'periodic')
    #     (data:ConstantDimensionalSpace 'constant')
    # }.
}
