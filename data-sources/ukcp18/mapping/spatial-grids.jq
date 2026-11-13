import "./mapping/utils" as UTILS;
import "./mapping/jsonld" as JSONLD;

# For each resolution available in UKCP18, this script generates a corresponding grids (dimensional space)
# and possibly the corresponding general discretizatyion specification.

# Resolutions currently in UKCP18:
# - global
#   - glb
# - metric
#   - 60km
#   - 25km
#   - 12km
#   - 5km
#   - 2.2km
#   - n216
# - non-metric
#   - country,
#   - region,
#   - river

# IRI of the area of use of OSGB36, a rectangle of WGS84 (named as the
# rectangles of the CORDEX domains: lower left and upper right corners)
def osgb_area_of_use: "georef:WGS84/regions/rectangle/-9.01,49.75:2.01,61.01";

{
    "@type": {
        "@id": {
            based_on_ds: "data:basedOnDimensionalSpace",
            discretization: "data:adoptsQuantization",
            resolution: "data:hasResolution",
            exact_bounding_region: "data:hasExactBoundingRegion",
            approximate_bounding_region: "data:hasApproximateBoundingRegion",
            pole: "data:hasReferencePoint",
            point_of: "data:isPointOf",
            region_of: "data:isRegionOf"
        },
        "geo:wktLiteral": {
            wkt: "geo:asWKT"
        }
    },
    "@language": {
        en: {
            label: "rdfs:label",
            comment: "rdfs:comment"
        }
    }
} as $properties |

[
    # OSGB grids
    (
        (60, 25, 12, 5) |
        "\(.)km" as $id |
        . as $km |
        (. * 1000) as $m |
        {
            resolution_id: $id,
            for_domain: "uk",
            "@id": "https://w3id.org/climate-change-kg/data/dimensions/geodetic/reference-frames/OSGB36/grids/\($id)",
            "@type": "data:DiscreteDimensionalSpace",
            label: "\($id) geodetic grid based on OSGB",
            comment: "A geodetic grid of resolution \($km)km x \($km)km, based on Ordnance Survey of Great Britain (OSGB).",
            based_on_ds: "georef:OSGB36",
            discretization: {
                "@id": "https://w3id.org/climate-change-kg/data/geodeticgrid/km/\($km)",
                based_on_ds: "dimension:geodetic",
                "@type": "data:SimpleRegularBinning",
                resolution: {
                    "@id": @uri "https://w3id.org/climate-change-kg/data/value/m/\($m)",
                    "@type": "top:Amount",
                    value: "\($m)",
                    uom: "https://w3id.org/climate-change-kg/data/unitsofmeasure/m"
                }
            },
            # (as its reference frame: the grid is within its area of use)
            approximate_bounding_region: osgb_area_of_use
        }
    ),


    # N216 grid
    {
        resolution_id: "n216",
        for_domain: "uk",
        "@id": "https://w3id.org/climate-change-kg/data/ukcp18/grids/N216",
        "@type": "data:DiscreteDimensionalSpace",
        label: "N216 geodetic grid",
        comment: "A global geodetic grid of approximate resolution 60km x 60km, developed by the UK Met Office.",
        based_on_ds: "dimension:geodetic",
        discretization: "https://w3id.org/climate-change-kg/data/geodeticgrid/km/60",
        exact_bounding_region: "dimension:geodetic/all"
    },

    # Regular angular grid
    {
        resolution_id: "60km",
        for_domain: "global",
        "@id": "https://w3id.org/climate-change-kg/data/ukcp18/grids/WGS84/60km",
        "@type": "data:DiscreteDimensionalSpace",
        label: "UKCP18 global geodetic grid",
        comment: "A global geodetic grid of approximate resolution 60km x 60km, based on WGS84.",
        based_on_ds: "georef:WGS84",
        discretization: "https://w3id.org/climate-change-kg/data/geodeticgrid/km/60",
        exact_bounding_region: "dimension:geodetic/all"
    },

    # CORDEX EUR-11 grid, fully defined among CORDEX domains
    {
        resolution_id: "12km",
        for_domain: "eur",
        "@id": "https://w3id.org/climate-change-kg/data/cordex/grids/EUR-11/ds"
    },

    # Rotated pole coordinates grids
    (
        # ( {km: 12, pole:{lat:39.25, long: 198.0}}, {km: 2.2, pole:{lat:37.5, long: 177.5}}) |
        {km: 2.2, pole:{lat:37.5, long: 177.5}} |
        {
            resolution_id: "\(.km)km",
            for_domain: "uk", #if .km == 12 then "eur" else "uk" end,
            "@id": "https://w3id.org/climate-change-kg/data/ukcp18/grids/rotated-WGS84/\(.km)km",
            "@type": "data:DiscreteDimensionalSpace",
            label: "UKCP18 \(.km)km grid on rotated pole coordinates",
            comment: "A geodetic grid of approximate resolution \(.km)km x \(.km)km, based on a rotated pole coordinate system.",
            based_on_ds: (.pole | {
                "@id": "georef:rotated-WGS84/\(.long),\(.lat)",
                "@type": "data:Continuum",
                label: "Rotated geodetic: pole \(.long)° \(.lat)°",
                comment: "Rotated geodetic dimensional space, with polar coordinates \(.long)° \(.lat)°, in reference to the World Geodetic System 1984 (WGS84).",
                based_on_ds: "georef:WGS84",
                pole: {
                    "@id": "georef:WGS84/points/\(.long),\(.lat)",
                    "@type": "data:GeodeticPoint",
                    point_of: "georef:WGS84",
                    label: "Geodetic point \(.long)° \(.lat)°",
                    comment: "Geodetic point with longitude \(.long)° and latitude \(.lat)°, in reference to the World Geodetic System 1984 (WGS84).",
                    wkt: "POINT(\(.long) \(.lat))"
                }
            }),
            discretization: {
                "@id": "https://w3id.org/climate-change-kg/data/ukcp18/grids/rotated-WGS84/\(.km)km/discretization",
                based_on_ds: "dimension:geodetic",
                "@type": "data:SimpleRegularBinning",
                resolution: (
                    (.km * 1000) as $m |
                    {
                        "@id": @uri "https://w3id.org/climate-change-kg/data/value/m/\($m)",
                        "@type": "top:Amount",
                        value: "\($m)",
                        uom: "https://w3id.org/climate-change-kg/data/unitsofmeasure/m"
                    }
                )
            }
            # exact_bounding_region: "dimension:geodetic/all"
        }
    ),

    # Non-metric subdivisions 
    (
        (
            {id: "country", items_label: "countries"},
            {id: "region", items_label: "administrative regions"},
            {id: "river", items_label: "river basin regions"}
        ) |
        {
            resolution_id: "\(.id)",
            for_domain: "uk",
            "@id": "https://w3id.org/climate-change-kg/data/ukcp18/regional-splits/\(.id)",
            "@type": "data:DiscreteDimensionalSpace",
            label: "UKCP18 \(.items_label)",
            comment: "Subdivision of UK by \(.items_label) as adopted in UKCP18.",
            based_on_ds: "dimension:geodetic"
        }
    )
] as $grids |

{
    "@context": {
        rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        rdfs: "http://www.w3.org/2000/01/rdf-schema#",
        top: "https://w3id.org/hacid/onto/top-level/",
        data: "https://w3id.org/hacid/onto/data/",
        geo: "http://www.opengis.net/ont/geosparql#",
        dimension: "https://w3id.org/climate-change-kg/data/dimensions/",
        georef: "https://w3id.org/climate-change-kg/data/dimensions/geodetic/reference-frames/"
    } + 
    ($properties | JSONLD::unpack),
    "@graph": [
        # OSGB
        {
            "@id": "georef:OSGB36",
            "@type": "data:Continuum",
            label: "Ordnance Survey of Great Britain (OSGB)",
            comment: "OSGB is a coordinate reference system for Great Britain.",
            based_on_ds: "dimension:geodetic",
            approximate_bounding_region: osgb_area_of_use
        },
        # The area of use of OSGB36 / British National Grid in the EPSG registry
        # (EPSG:27700, extent 4390): a rectangle in WGS84 longitude and
        # latitude, so a region of WGS84, which bounds OSGB36 (defined on
        # another projection) only approximately
        {
            "@id": osgb_area_of_use,
            "@type": "data:GeodeticRegion",
            region_of: "georef:WGS84",
            label: "Rectangular geodetic region -9.01° 49.75° : 2.01° 61.01°",
            comment: "Rectangular geodetic region comprised between lower left coordinates -9.01° 49.75° and upper right coordinates 2.01° 61.01°: the area of use of the OSGB36 / British National Grid coordinate reference system (EPSG:27700), Great Britain and the UK continental shelf.",
            wkt: "POLYGON((-9.01 49.75,-9.01 61.01,2.01 61.01,2.01 49.75,-9.01 49.75))"
        },
        ($grids | map(del(.resolution_id) | del(.for_domain)))
    ],
    grid_map: (
        $grids | UTILS::split_by(.for_domain) |
        with_entries(
            .value |= (
                UTILS::split_by(.resolution_id) |
                with_entries(
                    .value |= (
                        map(."@id") |
                        if length > 1 then
                            error("Potential conflict in UKCP18 spatial grid attribution: \(.)")
                        else
                            .[0]
                        end
                    )
                )
            )
        )
    )
}