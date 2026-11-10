# top:associatedWith is the catch-all property of the top-level ontology: most
# of the object properties of the ontologies are its sub-properties, and it is
# symmetric and transitive. With the inference of the published KG (GraphDB,
# RDFS-Plus) every triple of a sub-property would be an association too, and
# their symmetric and transitive closure would associate each resource with all
# those connected to it: a huge number of triples of little use.
#
# Only the axioms that give those inferences are removed: the property stays
# declared (with its labels, domain and range) for the few triples that use it
# directly (e.g. the collection of the variables of a model, associated with the
# model), which are then not inferred upon further.

PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX top: <https://w3id.org/hacid/onto/top-level/>

DELETE WHERE {
    GRAPH ?g {
        ?property rdfs:subPropertyOf top:associatedWith
    }
};

DELETE WHERE {
    GRAPH ?g {
        top:associatedWith a owl:TransitiveProperty
    }
};

DELETE WHERE {
    GRAPH ?g {
        top:associatedWith a owl:SymmetricProperty
    }
};

DELETE WHERE {
    GRAPH ?g {
        top:associatedWith owl:inverseOf top:associatedWith
    }
};
