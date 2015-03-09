using DataFramesIO
using FactCheck
using GeoJSON

include(joinpath(dirname(@__FILE__),"geojson_samples.jl"))

fc = GeoJSON.parse(collection)
df = to_dataframe(fc)
@fact size(df) => (1, 4)
@fact df[1,:STATE_ABBR] => "ZZ"
@fact df[1,:STATE_NAME] => "Top"
@fact df[1,:geometry] => GeometryCollection

buildings = GeoJSON.parse(osm_buildings)
df = to_dataframe(buildings)
@fact size(df) => (4, 4)
@fact df[:height] => [150, 130, 120, 140]
@fact map(typeof, df[:geometry]) => [Polygon, Polygon, MultiPolygon, Polygon]
@fact df[:color] => ["rgb(255,200,150)",
                     "rgb(180,240,180)",
                     "rgb(200,200,250)",
                     "rgb(150,180,210)"]
@fact all(DataFrames.isna(df[:id])) => true
@fact string(df2geojson(df)) => string(buildings)