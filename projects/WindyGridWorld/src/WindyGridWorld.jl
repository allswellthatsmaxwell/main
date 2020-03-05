module WindyGridWorld
include("./environment.jl")
using .Environment: WindyGridWorldEnv, GridWorld, Policy, reset!,
    Reinforce.finished, Reinforce.actions, Action, Reward, print_value_function, CellIndex,
    WorldState
using Reinforce, Base

function main()
    env = WindyGridWorldEnv(5, 4)
    A = Reinforce.actions(false)
    policy = Policy(0.1, 0.05, 1.0, env.world, A)
    run_one_episode(env, policy, A, monitoring = true)
    #Reinforce.run_episode(env, policy) do (s, a, r, s′)
    #    print("Taking $(a) transitioned state $(s) to state $(s′)" *
    #          "and gave a reward of $(r).")
    #    ## Use s, a, r, s′ to update the policy's value function
    #    ## ah but no it's too late! I want to update during the episode.
    #end
end

function run_one_episode(env::AbstractEnvironment, policy::AbstractPolicy,
                         A::Set{Action}; monitoring = false)
    s = env.state
    r::Reward = 0.0
    i = 0
    monitoring_freq = 100
    while !Reinforce.finished(env)
        a = Reinforce.action(policy, r, s, A)
        r, s′ = Reinforce.step!(env, s, a)
        update!(policy, s, a, r, s′, A)
        s = s′
        i += 1
        if monitoring && i % monitoring_freq == 0
            print_value_function(policy)
        end
    end
    if monitoring
        print_value_function(policy)
    end
end

main()

end
