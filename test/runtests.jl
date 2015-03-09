#
# Correctness Tests
#

my_tests = ["json2df.jl",
            "geojson2df.jl"]

@printf "Running tests:\n"

for my_test in my_tests
    @printf " * %s\n" my_test
    include(my_test)
end
