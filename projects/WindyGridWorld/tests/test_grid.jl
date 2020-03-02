include("../src/environment.jl")
using .Environment: CellIndex, FlatIndex, MustMoveGrid, flat_index, cell_index
using Test

struct Pair
    c::CellIndex
    f::FlatIndex
end

g = MustMoveGrid(6, 5)
Pair(t::Tuple{Int64}, f::FlatIndex) = Pair(CellIndex(t...), f)

pairs = (
    Pair(CellIndex(0, 0), 0),
    Pair(CellIndex(2, 0), 2),
    Pair(CellIndex(1, 1), 7),
    Pair(CellIndex(2, 1), 8),
    Pair(CellIndex(0, 2), 12),
    Pair(CellIndex(2, 2), 14)
)

@testset for p in pairs
    @test flat_index(g, p.c) == p.f
end

@testset for p in pairs
    @test cell_index(g, p.f) == p.c
end

