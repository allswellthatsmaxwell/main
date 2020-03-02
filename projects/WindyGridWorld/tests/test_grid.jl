include("../environment.jl")
using .Environment

using Test

struct Pair
    c::CellIndex
    f::FlatIndex
end
Pair(t::Tuple{Int64}, f::FlatIndex) = Pair(CellIndex(t...), f)
g = MustMoveGrid(6, 5)
test_c_to_f(p::Pair) = @test flat_index(g, p.c) == p.f
test_f_to_c(p::Pair) = @test cell_index(g, p.f) == p.c
c_to_f_pairs = (
    Pair((0, 0), 1),
    Pair((2, 0), 3),
    Pair((1, 1), 8),
    Pair((2, 1), 9),
    Pair((0, 2), 13),
    Pair((2, 2), 15)        
)
for pair in c_to_f_pairs
    test_c_to_f(pair)
end
