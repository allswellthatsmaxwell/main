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
    g::LightGraphs.SimpleGraph
end

function Grid(ntiles::Int64)
    g = LightGraphs.SimpleGraph(ntiles)    
end

Grid() = Grid(NTILES)

## A gridworld in which the agent must move at every timestep
struct MustMoveGrid <: Grid
end

function MustMoveGrid(ntiles)
    
end





g = make_grid(NTILES)

end
    
