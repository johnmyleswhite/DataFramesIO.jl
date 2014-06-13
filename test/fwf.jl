module TestFWF

using Base.Test
using DataFrames
using DataFramesIO

types = [ASCIIString, Float64, Int, UTF8String, Uint8]
widths = [2, 3, 3, 3, 3]
ns = [:A, :B, :C, :D, :E]

body = " a1.1 4  åå1  \n" *
       " b.2 -55∫ ∫ 2 \n" *
       "c  .3+6 çç  \t3\n"

file = tempname()
open(io -> print(io, body), file, "w")

df = DataFrame(
    x1 = ["a", "b", "c"],
    x2 = [1.1, 0.2, 0.3],
    x3 = [4, -55, 6],
    x4 = ["åå", "∫ ∫", "çç"],
    x5 = Uint8[1, 2, 3]
)

# Read from IOBuffer, unnamed
io = IOBuffer(body)
@test fwf2df(io, types, widths) == df

# Read from path, named
names!(df, ns)
@test fwf2df(file, types, widths, ns) == df

# Skip header
@test fwf2df(file, types, widths, ns, skipstart=1) == df[2:end, :]

# Read a subset of columns
s = [2, 4]
right = cumsum(widths)
left = [0, right[1:(end - 1)]] .+ 1
bounds = collect(zip(left, right))
@test fwf2df(file, types[s], bounds[s], ns[s]) == df[s]

# NA
nastrings = ASCIIString[" "^w for w=widths]
nastrings[3] = "-99"

body = " a1.1  4 åå1  \n" *
       " b.2 -55∫ ∫ 2 \n" *
       "     -99      \n"

df[3, :] = NA

io = IOBuffer(body)
@test isequal(df, fwf2df(io, types, widths, ns, nastrings = nastrings))

# Cleanup
rm(file)

end # module TestFWF
