#
# Correctness Tests
#

using Base.Test
using DataFrames
using DataFramesIO

my_tests = ["json.jl"]

@printf "Running tests:\n"

for my_test in my_tests
    @printf " * %s\n" my_test
    include(my_test)
end
