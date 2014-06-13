DataFramesIO.jl
===============

Wraps libraries for reading foreign file formats:

* Evan Miller's Stata, SPSS, ... reader
* Avik Sengupta's Excel reader
* JSON input/output
* Fixed-width text input/output

# Usage Example

    using DataFrames
    using DataFramesIO

    s =  """[{"id":1, "val":5.5}, {"id":2, "val": 6.6}]"""

    df = json2df(s)
    json = df2json(df)
    df2 = json2df(json)
