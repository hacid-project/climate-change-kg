PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX top: <https://w3id.org/hacid/onto/top-level/> 
PREFIX vars: <https://w3id.org/climate-change-kg/data/variables/>

INSERT {
    GRAPH <https://w3id.org/climate-change-kg/data/variables> {
        <https://w3id.org/climate-change-kg/data/variables>
            a top:Collection;
            rdfs:label "Standard variables"@en;
            rdfs:comment "Collection of all the standard variables represented in this knowledge graph."@en;
            top:hasComponent ?var_collection;
            top:hasMember ?var.
    }
}
WHERE {
    VALUES ?var_collection {vars:mip vars:cf}.
    ?var top:isMemberOf ?var_collection
};

INSERT {
    GRAPH <https://w3id.org/climate-change-kg/data/indices> {
        <https://w3id.org/climate-change-kg/data/indices>
            a top:Collection;
            rdfs:label "Standard indices"@en;
            rdfs:comment "Collection of all the standard indices represented in this knowledge graph."@en;
            top:hasComponent ?index_collection;
            top:hasMember ?index.
    }
}
WHERE {
    VALUES ?index_collection {
        <https://w3id.org/climate-change-kg/data/climdex/indices>
        <https://w3id.org/climate-change-kg/data/Climate-ADAPT/indices>
        <https://w3id.org/climate-change-kg/data/Copernicus-CCS/indices>
        <https://w3id.org/climate-change-kg/data/ETCCDI/indices>
        <https://w3id.org/climate-change-kg/data/UK-CRI/indices>
    }.
    ?index_collection top:hasMember ?index
};

