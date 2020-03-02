module Environment
export WindyGridWorldEnv

using Reinforce, LightGraphs

NTILES = 40

mutable struct WindyGridWorldEnv <: Reinforce.AbstractEnvironment
    state::Vector{Float64}
    reward::Float64
    actions(env, s) = []
end

## Let's make a grid. Let's start with a square one and if we
## want to get crazy later we can change it.
## How about an adjacency matrix as the data structure?
abstract type Grid end

## A gridworld in which the agent must move at every timestep
struct MustMoveGrid <: Grid    
    rows::Int64
    cols::Int64
    graph::SimpleGraph
end

MustMoveGrid(rows::Int64, cols::Int64) = MustMoveGrid(rows, cols,
                                                      SimpleGraph(rows * cols))
MustMoveGrid(ntiles::Int64) = MustMoveGrid(ntiles ÷ 2, ntiles ÷ 2)
MustMoveGrid() = MustMoveGrid(NTILES)

struct CellIndex
    row::Int64
    col::Int64
end

FlatIndex = Integer

function cell_index(g::Grid, i::FlatIndex)::CellIndex
    """
    returns the CellIndex for a FlatIndex
    """
    return CellIndex(i % g.rows, i ÷ g.cols)
end

function flat_index(g::Grid, cell::CellIndex)::FlatIndex
    """
    returns the FlatIndex for a CellIndex
    """
    return (1 + cell.row) + g.rows * cell.col
end

## Ah, wait, damn, I don't want this. This would be like teleportation.
function make_fully_connected(g::SimpleGraph, include_self_edges::Bool)::Nothing
    for v ∈ vertices(g)
        for u ∈ vertices(g)
            if u != v || include_self_edges
                add_edge!(g, u, v)
            end
        end
    end
end         

end

