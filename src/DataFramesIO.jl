module DataFramesIO
	using DataArrays
	using DataFrames
	using JSON

	export json2df, df2json
	# export xls2df, df2xls
	# export stata2df, df2stata
	# export spss2df, df2spss

	include("json.jl")
end
