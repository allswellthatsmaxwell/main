module Environment
export WindyGridWorldEnv

using Reinforce, Random, Base

include("./worlds.jl")
using .Worlds: GridWorld, CellIndex, FlatIndex, flat_index, adjacent

## If true, agent can move like a king in chess. If false,
## agent can only move up/down/left/right.
DIAGONAL_ALLOWED = false

Reward = Float64
Action = Integer

mutable struct WorldState
    cell::CellIndex
end

default_start_cell = CellIndex(0, 0)
default_goal_cell = CellIndex(4, 3)
WorldState() = WorldState(default_start_cell)

mutable struct WindyGridWorldEnv <: Reinforce.AbstractEnvironment
    state::WorldState
    start::CellIndex
    goal::CellIndex
    reward::Reward
    world::GridWorld
end

WindyGridWorldEnv() = WindyGridWorldEnv(WorldState(),
                                  default_start_cell,
                                  default_goal_cell,
                                  0,
                                  GridWorld())

WindyGridWorldEnv(rows::Integer, cols::Integer) = WindyGridWorldEnv(
    WorldState(),
    default_start_cell,
    default_goal_cell,
    0,
    GridWorld(rows=rows, cols=cols))

WindyGridWorldEnv(start_cell::CellIndex,
                  rows::Integer, cols::Integer) = WindyGridWorldEnv(
                   WorldState(start_cell),
                   start_cell,
                   default_goal_cell,
                   0,
                   GridWorld(rows=rows, cols=cols))

mutable struct Policy <: Reinforce.AbstractPolicy
    """
    :param Q: maps states to estimated future rewards.
    :param ε: the ε for ε-greedy methods.
    :param rows, cols: the dimensions of the world this policy
    operates within.
    """
    ε::Float64
    Q::Dict{Integer, Float64}
    world::GridWorld
    rng::MersenneTwister
end

function Policy(ε::Float64, world::GridWorld)    
    Q = Dict([(i, 0) for i in 1:(world.rows * world.cols)])
    rng = MersenneTwister()
    return Policy(ε, Q, world, rng)
end

Worlds.adjacent(p::Policy, i::FlatIndex, j::FlatIndex) = adjacent(
    p.rows, p.cols, i, j)
Worlds.adjacent(p::Policy, i::FlatIndex, s::WorldState) = adjacent(
    p.world.rows, p.world.cols, i,
    flat_index(p.world.rows, s.cell))

function find_move_for_target(world::GridWorld, current_cell::CellIndex,
                              target_cell::CellIndex)::Action
    """
    Returns the action that will move current_cell to target_cell, or if
    there is no such action, error.
    """
    for (action, move) in world.actions_to_moves
        if move(world, current_cell) == target_cell
            return action
        end
    end
    error("Failed to find a way to move from $(current_cell) to $(target_cell)")
end

struct TVPair
    tile::FlatIndex
    value::Float64
end

# Base.length(TVPair) = 1

function find_best_action(policy::Policy, s::WorldState, A::Set{Action})::Action
    """
    Of the actions that can be taken from state s, 
    returns the one with the highest value.
    """
    
    available_actions = []    
    for (tile, value) in policy.Q
        if adjacent(policy, tile, s)
            push!(available_actions, TVPair(tile, value))
        end
    end
    best_value = maximum([p.value for p in available_actions])
    best_tile::FlatIndex  = [p.tile for p in available_actions
                             if p.value == best_value][1]
    return find_move_for_target(policy.world,
                                s.cell,
                                CellIndex(policy.world, best_tile))
end

function Reinforce.action(policy::Policy, r::Reward, s::WorldState,
                          A::Set{Action})::Action
    """
    Take in the last reward `r`, current state `s`,
    and set of valid actions `A = actions(env, s)`,
    then return the next action `a`.
    Uses ε-greedy, ε taken from the policy object.

    :param A: Set of all actions.
    """
    ## let's use episilon-greedy - do the best action from Q
    ## with probability 1 - ε, and a random action from it with probability ε.
    r = rand(policy.rng)
    if r < policy.ε
        return rand(policy.rng, A)
    else
        return find_best_action(policy, s, A)
    end
end

function Reinforce.reset!(env::WindyGridWorldEnv)
    env.state = WorldState(env.start)
end

function Reinforce.step!(env::WindyGridWorldEnv, state::WorldState,
                         a::Action)::Tuple{Reward, WorldState}
    """ 
    :param a: the action to take
    """
    if finished(env, state)
        reward = 0 ## is this enough?
        s′ = state
    else
        reward = -1
        ## update the state
        move::Function = env.world.actions_to_moves[a]
        new_pos::CellIndex = move(env.world, state.cell)
        s′ = WorldState(new_pos)
        ## update the approximation of the value function
    end
    env.reward = reward
    env.state = s′
    return reward, s′
end

Reinforce.finished(env::WindyGridWorldEnv) = env.state.cell == env.goal
Reinforce.finished(env::WindyGridWorldEnv, s′) = finished(env)
## Base.done(env::WindyGridWorldEnv) = finished(env)

ismdp(env::WindyGridWorldEnv) = true
maxsteps(env::WindyGridWorldEnv) = 0

function Reinforce.actions(diagonal_allowed::Bool)::Set{Action}
    lim = if (diagonal_allowed) 9 else 5 end
    return Set(1:lim)
end
    
## do I need, like, move functions?
Reinforce.actions(env::WindyGridWorldEnv,
                  s::WorldState) = Reinforce.actions(DIAGONAL_ALLOWED)

end

