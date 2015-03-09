
function propertynames(obj::AbstractFeatureCollection)
    # returns String[]
    columns = Set()
    for feature in features(obj)
        if has_properties(feature)
            for key in keys(properties(feature))
                if in(key, columns)
                    continue
                end
                push!(columns, key)
            end
        end
    end
    return [["id","geometry"],sort(collect(columns))]
end

function convert(::Type{DataFrames.DataFrame}, obj::AbstractFeatureCollection)
    nrows = has_features(obj) ? length(features(obj)) : 0
    if nrows == 0
        return DataFrames.DataFrame()
    end
    colnames = propertynames(obj)
    ncols = length(colnames)
    df = DataFrames.DataFrame([[Any, AbstractGeometry], repeat([Any], inner = [ncols-2])],
                   convert(Vector{Symbol}, colnames), nrows)
    for i in 1:nrows
        feat = features(obj)
        df[i, 1] = has_id(feat[i]) ? id(feat[i]) : NA
        df[i, 2] = geometry(feat[i])
        if has_properties(feat[i])
            for j in 3:ncols
                df[i, j] = get(properties(feat[i]), colnames[j], NA)
            end
        end
    end
    return df
end
to_dataframe(obj::AbstractFeatureCollection) = convert(DataFrames.DataFrame, obj)

function df2geojson(adf::AbstractDataFrame; geometry=:geometry) # -> GeoJSON.FeatureCollection
    nrows, ncols = size(adf)
    cnames = names(adf)
    hasid = in(:id, cnames)
    collection = FeatureCollection(Feature[])
    sizehint!(collection.features, nrows)
    for i in 1:nrows
        push!(collection.features, Feature(adf[i, :geometry], Dict{String,Any}()))
        if hasid && adf[i, :id] !== NA
            collection.features[i].id = adf[i, :id]
        end
        for j in 1:ncols
            if adf[i, j] !== NA && cnames[j] !== :geometry && cnames[j] !== :id
                collection.features[i].properties[stringnames[j]] = adf[i, j]
            end
        end
    end
    return collection
end
