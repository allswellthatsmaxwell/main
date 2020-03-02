module Environment
export WindyGridWorldEnv

using Reinforce

include("./worlds.jl")
using .Worlds: GridWorld

mutable struct WindyGridWorldEnv <: Reinforce.AbstractEnvironment
    state::Vector{Float64}
    reward::Float64
    actions(env, s) = []
end

end

