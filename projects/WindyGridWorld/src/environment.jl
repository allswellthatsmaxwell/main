module Environment
export WindyGridWorldEnv

using Reinforce, Random, Base, JLD
import Base: ==

include("./worlds.jl")
using .Worlds: GridWorld, CellIndex, FlatIndex, flat_index, adjacent

## If true, agent can move like a king in chess. If false,
## agent can only move up/down/left/right.
DIAGONAL_ALLOWED = false

Reward = Float64
Action = Int

default_start_cell = CellIndex(1, 1)
default_goal_cell = CellIndex(5, 4)

struct WorldState
    cell::CellIndex
end

WorldState() = WorldState(default_start_cell)

Base.isequal(s1::WorldState, s2::WorldState) = s1.cell == s2.cell
==(s1::WorldState, s2::WorldState) = s1.cell == s2.cell
Base.hash(s::WorldState, h::UInt) = Base.hash(s.cell, h)

mutable struct WindyGridWorldEnv <: Reinforce.AbstractEnvironment
    state::WorldState
    start::CellIndex
    goal::CellIndex
    reward::Reward
    world::GridWorld
end

WindyGridWorldEnv(rows::Int, cols::Int,
                  goal::CellIndex, p_tile_removal::Float64) = WindyGridWorldEnv(
                      WorldState(default_start_cell),
                      default_start_cell,
                      goal,
                      0,
                      GridWorld(rows, cols, p_tile_removal))

WindyGridWorldEnv() = WindyGridWorldEnv(
    WorldState(),
    default_start_cell,
    default_goal_cell,
    0,
    GridWorld())

WindyGridWorldEnv(rows::Int, cols::Int, goal::CellIndex) = WindyGridWorldEnv(
    WorldState(default_start_cell),
    default_start_cell,
    goal,
    0,
    GridWorld(rows, cols),
    0.0)

WindyGridWorldEnv(rows::Int, cols::Int) = WindyGridWorldEnv(
    rows, cols, default_goal_cell)    



WindyGridWorldEnv(start_cell::CellIndex,
                  rows::Int, cols::Int) = WindyGridWorldEnv(
                   WorldState(start_cell),
                   start_cell,
                   default_goal_cell,
                   0,
                   GridWorld(rows, cols))

mutable struct Policy <: Reinforce.AbstractPolicy
    """
    :param ε: the ε for ε-greedy methods.
    :param α: the learning step size.
    :param γ: the discount rate.
    :param Q: maps states to estimated future rewards.    
    :param world: the world this policy operates within.
    """
    ε::Float64
    α::Float64
    γ::Float64    
    Q::Dict{WorldState, Dict{Action, Float64}}
    world::GridWorld
    rng::MersenneTwister
end

function save(policy::Policy, path::String; name::String = "A")
    JLD.jldopen("path", "w") do file
        # addrequire(file, Environment)
        JLD.@write file policy
        #JLD.write(file, "policy", policy)
    end
end

function to_csv(Q::Dict{WorldState, Dict{Action, Float64}}, path::String)
    rows = []
    for (state, actions) in Q
        for (action, value) in actions
            row = join([state.cell.row, state.cell.col, action, value], ",")
            push!(rows, row)
        end
    end
    csv = join(rows, "\n")
    open(path, "w") do io
        write(io, csv)
    end    
end

function from_csv(path::String)::Dict{WorldState, Dict{Action, Float64}}
    

end

function save(policy::Policy, path::String)
    to_csv(policy.Q, path)
end

function load(path::String; name::String = "A")
    c = jldopen(path, "r") do file
        read(file, name)
    end
end

function print_value_function(policy::Policy)
    parts = []
    for (state, actions_to_values) in policy.Q
        println(state)
        for (action, value) in actions_to_values
            println("\t$(action): $(value)")
        end
    end
end

Base.show(io::IO, state::WorldState) = print("$(state.cell)")

function Reinforce.update!(policy::Policy, s::WorldState,
                           a::Action, r::Reward, s′::WorldState,
                           A::Set{Action})
    Q = policy.Q
    best_action = _find_best_action(policy, s′)
    max_action_value = Q[s′][best_action]
    Q[s][a] = Q[s][a] + policy.α * (r + policy.γ * max_action_value - Q[s][a])
end

function _initialize_policy(world::GridWorld,
                            A::Set{Action})::Dict{WorldState,
                                                  Dict{Action, Float64}}
    Q = Dict()    
    for row in 1:world.rows
        for col in 1:world.cols
            actions_to_values = Dict([(a, 0.0) for a in A])
            Q[WorldState(CellIndex(row, col))] = actions_to_values
        end
    end    
    return Q
end

function Policy(ε::Float64, α::Float64, γ::Float64,
                world::GridWorld, A::Set{Action})
    Q = _initialize_policy(world, A)
    rng = MersenneTwister()
    return Policy(ε, α, γ, Q, world, rng)
end

Worlds.adjacent(p::Policy, i::FlatIndex, j::FlatIndex) = adjacent(
    p.rows, p.cols, i, j)
Worlds.adjacent(p::Policy, i::FlatIndex, s::WorldState) = adjacent(
    p.world.rows, p.world.cols, i,
    flat_index(p.world.rows, s.cell))

function _find_move_for_target(world::GridWorld, current_cell::CellIndex,
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

function _find_best_action(policy::Policy, s::WorldState)::Action
    """
    Of the actions that can be taken from state s, 
    returns the one with the highest value. If there are multiple
    actions with the highest value, returns a random one of those.
    """
    A = policy.Q[s] ## error is here
    best_value = maximum([value for (action, value) in A])
    best_actions = [action for (action, value) in A
                    if value == best_value]
    return rand(policy.rng, best_actions)
    
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
        return _find_best_action(policy, s)
    end
end

function Reinforce.reset!(env::WindyGridWorldEnv)
    env.state = WorldState(env.start)
end

function ishole(world::GridWorld, cell::CellIndex)
    return !has_vertex(world.graph, cell)
end
ishole(world::GridWorld, state::WorldState) = ishole(world, state.cell)
ishole(world::GridWorld, i::FlatIndex) = ishole(world, CellIndex(i))

function Reinforce.step!(env::WindyGridWorldEnv, state::WorldState,
                         a::Action)::Tuple{Reward, WorldState}
    """ 
    :param a: the action to take
    """
    if finished(env, state)
        reward = 0.0
        s′ = state
    elseif ishole(env.world, state)
        reward = -1.0
        reset!(env)
        s′ = env.start        
    else        
        reward = -1.0
        move::Function = env.world.actions_to_moves[a]
        new_pos::CellIndex = move(env.world, state.cell)
        s′ = WorldState(new_pos)
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

