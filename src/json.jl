# function tighttypes!(adf::AbstractDataFrame)
#     nrows, ncols = size(adf)
#     for j in 1:ncols
#         T = None
#         col = adf[j]
#         for i in 1:nrows
#             if !isna(col[i])
#                 T = typejoin(T, typeof(col[i]))
#             end
#         end
#         adf[j] = convert(DataVector{T}, col)
#     end
#     return
# end

function json2df(s::String) # -> DataFrame
    # TODO: Handle NA's properly
    # TODO: Optimize memory access
    # TODO: Implement and call tighttypes!(df)
    arrayofhashes = JSON.parse(s)
    nrows = length(arrayofhashes)
    if nrows == 0
        return DataFrame()
    end
    colnames = collect(reduce((colall, row) -> union(colall, Set(collect(keys(row)))), Set(), arrayofhashes))
    sort!(colnames)
    # Check that keys are valid column names
    ncols = length(colnames)
    df = DataFrame(repeat([Any], inner = [ncols]), convert(Vector{Symbol}, colnames), nrows)
    for i in 1:nrows
        for j in 1:ncols
            df[i, j] = get(arrayofhashes[i], colnames[j], NA)
        end
    end
    # tighttypes!(df)
    # clean_colnames!(df)
    return df
end

function df2json(adf::AbstractDataFrame) # -> UTF8String
    nrows, ncols = size(adf)
    cnames = colnames(adf)
    arrayofhashes = Array(Dict{UTF8String, Any}, nrows)
    for i in 1:nrows
        arrayofhashes[i] = Dict{UTF8String, Any}()
        for j in 1:ncols
            arrayofhashes[i][cnames[j]] = adf[i, j]
        end
    end
    return JSON.json(arrayofhashes)
end
