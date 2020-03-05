module WindyGridWorld
include("./environment.jl")
using .Environment: WindyGridWorldEnv, GridWorld, Policy, reset!,
    Reinforce.finished, Reinforce.actions, Action, Reward, print_value_function, CellIndex,
    WorldState
using Reinforce, Base, ArgParse

defaults = Dict("rows" => 5, "cols" => 4, "goalrow" => 4, "goalcol" => 3)

function read_arg(arg, parsed_args)
    
    val = parsed_args[arg]
    if val == nothing     
        return defaults[arg]
    else
        return val
    end
end

function main()
    parsed_args = parse_args(s)
    rows = read_arg("rows", parsed_args)
    cols = read_arg("cols", parsed_args)
    goalrow = read_arg("goalrow", parsed_args)
    goalcol = read_arg("goalcol", parsed_args)
    env = WindyGridWorldEnv(rows, cols, CellIndex(goalrow, goalcol))
    A = Reinforce.actions(false)
    policy = Policy(0.1, 0.05, 1.0, env.world, A)
    for _ in 1:10000
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
    for row in 1:env.world.rows
        for col in 1:env.world.cols
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

s = ArgParseSettings()
@add_arg_table! s begin
    "--rows"
        help = "Number of rows in the world."
        arg_type = Int
    "--cols"
        help = "Number of columns in the world."
        arg_type = Int
    "--goalrow"
        help = "row to place the goal at."
        arg_type = Int
    "--goalcol"
        help = "column to place the goal at."
        arg_type = Int
end

main()

end
