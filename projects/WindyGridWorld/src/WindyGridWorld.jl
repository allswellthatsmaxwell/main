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
    for _ in 1:1000
        run_one_episode(env, policy, A, monitoring = false)
    end
    print_value_function(policy)
    run_one_episode(env, policy, A, showpath = true)
end

function run_one_episode(env::AbstractEnvironment, policy::AbstractPolicy,
                         A::Set{Action}; monitoring = false, showpath = false)
    s = env.state
    r::Reward = 0.0
    i = 0
    monitoring_freq = 100
    if showpath show_position(env, s) end
    while !Reinforce.finished(env)        
        a = Reinforce.action(policy, r, s, A)
        r, s′ = Reinforce.step!(env, s, a)
        update!(policy, s, a, r, s′, A)
        s = s′
        i += 1
        if monitoring && i % monitoring_freq == 0
            print_value_function(policy)
        end
        if showpath show_position(env, s′) end
    end
    reset!(env)
end

function show_position(env::WindyGridWorldEnv, s::WorldState)    
    for col in 0:(env.world.cols - 1)
        for row in 0:(env.world.rows - 1)
            cell = CellIndex(row, col)
            if s == WorldState(cell)
                print("○")
            elseif cell == env.goal
                print("✗")                
            else
                print("■")
            end
        end
        println()
    end
    println()
end

main()

end
