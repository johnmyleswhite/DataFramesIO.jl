module DataFramesIO

using DataFrames
using JSON

export json2df, df2json,
       fwf2df #, df2fwf,
       # rda2df, df2rda,
       # xls2df, df2xls,
       # stata2df, df2stata,
       # spss2df, df2spss

include("fwf.jl")
include("json.jl")

end # module DataFramesIO
