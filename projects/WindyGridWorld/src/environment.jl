module Environment
export WindyGridWorld

using Reinforce

include("./worlds.jl")
using .Worlds: GridWorld, CellIndex

## If true, agent can move like a king in chess. If false,
## agent can only move up/down/left/right.
DIAGONAL_ALLOWED = false
action_set(diagonal_allowed) = DiscreteSet(1:(8 if diagonal_allowed else 4))

Reward = Float64

mutable struct WorldState
    position::CellIndex
end

default_start_cell = CellIndex(0, 0)
default_goal_cell = CellIndex(4, 3)
WorldState() = WorldState(start_cell)

mutable struct WindyGridWorld <: Reinforce.AbstractEnvironment
    state::WorldState
    start::CellIndex
    goal::CellIndex
    reward::Reward
    world::GridWorld
end

WindyGridWorld() = WindyGridWorld(WorldState(),
                                  default_start_cell,
                                  default_goal_cell,
                                  0,
                                  GridWorld())

WindyGridWorld(rows::Integer, cols::Integer) = WindyGridWorld(
    WorldState(),
    default_start_cell,
    default_goal_cell,
    0,
    GridWorld(rows=rows, cols=cols))

WindyGridWorld(start_cell::CellIndex,
               rows::Integer, cols::Integer) = WindyGridWorld(
                   WorldState(start_cell),
                   start_cell,
                   default_goal_cell,
                   0,
                   GridWorld(rows=rows, cols=cols))

function reset!(env::WindyGridWorld)
    env.position = env.start_cell
end

function step!(env::WindyGridWorld, state::WorldState,
               a::Int)::Tuple{Reward, WorldState}
    """ 
    :param a: the action to take
    """
    if finished(env, state):
        
    else
end

finished(env::WindyGridWorld, s') = env.state.position == goal_cell

ismdp(env::WindyGridWorld) = true
maxsteps(env::WindyGridWorld) = 0

 ## do I need, like, move functions?
actions(env::WindyGridWorld, s::WorldState) = action_set(DIAGONAL_ALLOWED)

end

