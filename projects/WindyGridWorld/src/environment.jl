module Environment
export WindyGridWorld

using Reinforce, Random

include("./worlds.jl")
using .Worlds: GridWorld, CellIndex

## If true, agent can move like a king in chess. If false,
## agent can only move up/down/left/right.
DIAGONAL_ALLOWED = false
action_set(diagonal_allowed) = DiscreteSet(1:(8 if diagonal_allowed else 4))

Reward = Float64

mutable struct WorldState
    cell::CellIndex
    index::FlatIndex
end

default_start_cell = CellIndex(0, 0)
default_goal_cell = CellIndex(4, 3)
WorldState(cell::CellIndex) = WorldState(cell, flat_index(cell))
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

mutable struct Policy <: AbstractPolicy
    """
    :param Q: maps states to estimated future rewards.
    :param ε: the ε for ε-greedy methods.
    :param rows, cols: the dimensions of the world this policy
    operates within.
    """
    ε::Float64
    Q::Dict{Integer, Float64}
    world::WindyGridWorld
    rng::MersenneTwister
end

function Policy(ε::Float64, world::WindyGridWorld)    
    Q = Dict([(i, 0) for i in 1:(world.rows * world.cols)])
    rng = MersenneTwister()
    return Policy(ε, Q, world, rng)
end

adjacent(p::Policy, i::FlatIndex, j::FlatIndex) = adjacent(p.rows, p.cols, i, j)
adjacent(p::Policy, i::FlatIndex, s::WorldState) = adjacent(
    p.rows, p.cols, i, s.index)

function find_move_for_target(world::GridWorld, current_cell::CellIndex,
                              target_cell::CellIndex)
    for action, move in world.actions_to_moves:
        if move(policy.world, s.cell) == target_cell
            return action
        end
    end
    error("Failed to find a way to move from $(current_cell) to $(target_cell)")


function find_best_action(policy::Policy, s::WorldState, actions)
    struct Pair
        tile::FlatIndex
        value::Float64
    end

    available_actions = []    
    for (tile, value) in policy.Q
        if adjacent(policy, tile, s)
            append!(available_actions, Pair(tile, value))
        end
    end
    best_value = max([p.value for p in available_actions])
    best_tile  = [p.tile for p in available_actions
                  if p.value == best_value][0]
    return find_move_for_target(policy.world, CellIndex(best_tile))
end

function action(policy::Policy, r::Reward, s::WorldState, actions)
    ## return the next action
    ## let's use episilon-greedy - do the best action from Q
    ## with probability 1 - ε, and a random action from it with probability ε.
    r = rand(policy.rng)
    if r < policy.ε
        return rand(policy.rng, actions)
    else
        return find_best_action(policy, s, actions)
    end
end

function reset!(env::WindyGridWorld)
    env.position = env.start_cell
end

function step!(env::WindyGridWorld, state::WorldState,
               a::Int)::Tuple{Reward, WorldState}
    """ 
    :param a: the action to take
    """
    if finished(env, state):
        reward = 0 ## is this enough?
        s' = state
    else
        reward = -1
        ## update the state
        move::Function = env.world.actions_to_moves[a]
        new_pos::CellIndex = move(env.world, state)
        s' = WorldState(new_pos)
        ## update the approximation of the value function
    end
    env.reward = reward
    env.state = s'
    return reward, s'
end

finished(env::WindyGridWorld, s') = env.state.position == goal_cell

ismdp(env::WindyGridWorld) = true
maxsteps(env::WindyGridWorld) = 0

 ## do I need, like, move functions?
actions(env::WindyGridWorld, s::WorldState) = action_set(DIAGONAL_ALLOWED)

end

