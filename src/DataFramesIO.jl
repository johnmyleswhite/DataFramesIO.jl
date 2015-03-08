module DataFramesIO
	using DataArrays
	using DataFrames
	using JSON
	using GeoJSON

	export json2df, df2json
	export geojson2df, df2geojson
	# export xls2df, df2xls
	# export stata2df, df2stata
	# export spss2df, df2spss

	include("json2df.jl")
	include("geojson2df.jl")
end
