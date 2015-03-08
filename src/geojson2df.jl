

function propertynames(obj::GeoJSON.FeatureCollection)
    columns = Set()
    for feature in obj.features
        if isdefined(feature, :properties)
            for key in keys(feature.properties)
                if in(key, columns)
                    continue
                end
                push!(columns, key)
            end
        end
    end
    return [["id","geometry"],sort(collect(columns))]
end

function geojson2df(obj::GeoJSON.FeatureCollection)
    nrows = length(obj.features)
    if nrows == 0
        return DataFrame()
    end
    colnames = propertynames(obj)
    ncols = length(colnames)
    df = DataFrame([[Any, GeoJSON.Geometry], repeat([Any], inner = [ncols-2])],
                   convert(Vector{Symbol}, colnames), nrows)
    for i in 1:nrows
        df[i, 1] = GeoJSON.hasid(obj.features[i]) ? obj.features[i].id : NA
        df[i, 2] = obj.features[i].geometry
        if isdefined(obj.features[i], :properties)
            for j in 3:ncols
                df[i, j] = get(obj.features[i].properties, colnames[j], NA)
            end
        end
    end
    return df
end

function df2geojson(adf::AbstractDataFrame; geometry=:geometry) # -> GeoJSON.FeatureCollection
    nrows, ncols = size(adf)
    cnames = names(adf)
    stringnames = map(string, cnames)
    collection = FeatureCollection(Feature[])
    sizehint!(collection.features, nrows)
    for i in 1:nrows
        push!(collection.features, Feature(adf[i, :geometry], Dict{String,Any}()))
        if adf[i, :id] !== NA
            collection.features[i].id = adf[i, :id]
        end
        for j in 3:ncols
            if adf[i, j] !== NA
                collection.features[i].properties[stringnames[j]] = adf[i, j]
            end
        end
    end
    return collection
end
