module Environment

using Reinforce

struct WindyGridWorld <: Reinforce.AbstractEnvironment
    actions(env, s) = []
end

    
