module WindyGridWorld
include("./environment.jl")
using .Environment: WindyGridWorldEnv, GridWorld, Policy, reset!
using Reinforce

function main()
    env = WindyGridWorldEnv()
    policy = Policy(0.1, env.world)
    Reinforce.run_episode(env, policy) do (s, a, r, s′)
        println("Taking $(a) transitioned state $(s) to state $(s′) and gave a reward of $(r).")
    end
end

main()

end
