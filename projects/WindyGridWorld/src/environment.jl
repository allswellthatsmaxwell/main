module Environment
export WindyGridWorldEnv

using Reinforce

mutable struct WindyGridWorldEnv <: Reinforce.AbstractEnvironment
    state::Vector{Float64}
    reward::Float64
    actions(env, s) = []
end

## Let's make a grid. Let's start with a square one and if we
## want to get crazy later we can change it.
## How about an adjacency matrix as the data structure?

end
    
