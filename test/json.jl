module TestJSON

using Base.Test
using DataFrames
using DataFramesIO

s =  """[
{
  "id":1,
  "company":"Telstra",
  "symbol":"ASX:TLS",
  "price":5.27
},
{
  "id":2,
  "company":"BHP",
  "symbol":"ASX:BHP",
  "price":37.77
},
{
  "id":3,
  "company":"Commonwealth Bank of Australia",
  "symbol":"ASX:CBA",
  "price":77.58
}
]"""

df = json2df(s)
@test isequal(size(df, 1), 3)
@test isequal(size(df, 2), 4)
@test isequal(names(df), [:company, :id, :price, :symbol])
@test isequal(df[3, :id], 3)
@test isequal(df[3, :price], 77.58)
json = df2json(df)
df2 = json2df(json)
@test df == df2

end # module TestJSON
