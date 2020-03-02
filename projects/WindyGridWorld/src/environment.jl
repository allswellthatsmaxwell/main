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
    graph::SimpleGraph
end

function MustMoveGrid(ntiles::Int64)
    graph = SimpleGraph(ntiles)
    make_fully_connected(graph, false)
    return MustMoveGrid(graph)
end

MustMoveGrid() = MustMoveGrid(NTILES)


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
