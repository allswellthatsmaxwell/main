include("../src/worlds.jl")
using .Worlds: CellIndex, FlatIndex, GridWorld, flat_index
using Test

struct Pair
    c::CellIndex
    f::FlatIndex
end

g = GridWorld(6, 5)
Pair(t::Tuple{Int64}, f::FlatIndex) = Pair(CellIndex(t...), f)

pairs = (
    Pair(CellIndex(1, 1), 1),    
    Pair(CellIndex(3, 1), 3),
    
    Pair(CellIndex(1, 2), 7),
    Pair(CellIndex(2, 2), 8),
    Pair(CellIndex(3, 2), 9),
    
    Pair(CellIndex(1, 3), 13),
    Pair(CellIndex(3, 3), 15),
    Pair(CellIndex(6, 5), 30),
    Pair(CellIndex(1, 5), 25)
)

@testset for p in pairs
    @test flat_index(g, p.c) == p.f
end

@testset for p in pairs
    @test CellIndex(g, p.f) == p.c
end

