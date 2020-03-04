module WindyGridWorld
include("./environment.jl")
using .Environment: WindyGridWorldEnv, GridWorld, Policy, reset!, Reinforce.finished
using Reinforce

function main()
    env = WindyGridWorldEnv()
    policy = Policy(0.1, 1, env.world)
    Reinforce.run_episode(env, policy) do (s, a, r, s′)
        print("Taking $(a) transitioned state $(s) to state $(s′)" *
              "and gave a reward of $(r).")
        ## Use s, a, r, s′ to update the policy's value function
        ## ah but no it's too late! I want to update during the episode.
    end
end

function run(env::AbstractEnvironment, policy::AbstractPolicy)
    s = env.state
    r = 0
    A = Reinforce.actions(false)
    while !Reinforce.finished(env)
        a = Reinforce.action(policy, r, s, A)
        reward, s′ = Reinforce.step!(env, s, a)
        update!(policy, s, a, r, s′)
    end

main()

end
