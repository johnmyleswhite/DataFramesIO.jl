using DataFramesIO, FactCheck

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
@fact size(df, 1) => 3
@fact size(df, 2) => 4
@fact names(df) => [:company, :id, :price, :symbol]
@fact df[3, :id] => 3
@fact df[3, :price] => roughly(77.58)
json = df2json(df)
df2 = json2df(json)
@fact df => df2
