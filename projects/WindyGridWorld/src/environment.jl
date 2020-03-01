module Environment
export WindyGridWorldEnv

using Reinforce

mutable struct WindyGridWorldEnv <: Reinforce.AbstractEnvironment
    state::Vector{Float64}
    reward::Float64
    actions(env, s) = []
end

end
    
