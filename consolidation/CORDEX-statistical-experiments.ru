# The CORDEX-CMIP5 experiments (a domain and an experiment, e.g.
# cordex.EUR-44i.rcp85) with statistical downscalings.
#
# The mapping of the CORDEX-CMIP5 datasets maps each page of the search results
# on its own, so it cannot tell whether an experiment has both dynamical and
# statistical downscalings: its node is a ccso:ClimateModelIntercomparisonExperiment
# and a ccso:DynamicalDownscaling as given by the records of the regional
# climate models, a ccso:EnsembleProjectionProduction and a ccso:Downscaling as
# given by those of the statistical models (statistical_downscaling_models in
# data-sources/cordex-cmip5/mapping/data-issues.json, see
# data-sources/cordex-cmip5/DECISIONS.md). Here, once all the records are
# loaded:
# - an experiment whose components are all statistical downscalings is a
#   ccso:StatisticalDownscaling (in CORDEX-CMIP5, those of the domain AUS, with
#   BOM-SDM only);
# - an experiment with a statistical downscaling among its components is not a
#   climate simulation: the types given by the records of the regional climate
#   models are removed (in CORDEX-CMIP5, cordex.EUR-44i.historical and
#   cordex.EUR-44i.rcp85, with DeepESD-EE and regional climate models).
# The ensembles of the statistical downscalings (each of a domain, experiment
# and model, and of a driving model too) are typed by the mapping.

PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX top:  <https://w3id.org/hacid/onto/top-level/>
PREFIX ccso: <https://w3id.org/hacid/onto/ccso/>

INSERT {
    GRAPH ?graph { ?experiment rdf:type ccso:StatisticalDownscaling }
}
WHERE {
    GRAPH ?graph {
        ?experiment rdf:type ccso:Downscaling ;
            top:hasComponent ?ensemble .
        ?ensemble rdf:type ccso:StatisticalDownscaling .
    }
    FILTER NOT EXISTS {
        ?experiment top:hasComponent ?other .
        ?other rdf:type ccso:DynamicalDownscaling .
    }
} ;

DELETE {
    GRAPH ?graph {
        ?experiment rdf:type ccso:ClimateModelIntercomparisonExperiment , ccso:DynamicalDownscaling .
    }
}
WHERE {
    GRAPH ?graph {
        ?experiment rdf:type ccso:Downscaling ;
            top:hasComponent ?ensemble .
        ?ensemble rdf:type ccso:StatisticalDownscaling .
    }
}
