module Environment
export WindyGridWorld

using Reinforce

include("./worlds.jl")
using .Worlds: GridWorld, CellIndex

mutable struct WorldState
    position::CellIndex
end

start_cell = CellIndex(0, 0)
goal_cell = CellIndex(4, 3)
WorldState() = WorldState(start_cell)

mutable struct WindyGridWorld <: Reinforce.AbstractEnvironment
    state::WorldState
    reward::Float64    
end

WindyGridWorld() = WindyGridWorld(WorldState(), 0)

function reset!(env::WindyGridWorld)
    env.position = start_cell
end

function step!(env::WindyGridWorld, state::WorldState,
               a::Int)::Tuple{Float64, WorldState}
end

finished(env::WindyGridWorld, s') = env.state.position == goal_cell

actions(env::WindyGridWorld, s::WorldState) = [] ## do I need, like, move functions?

end

