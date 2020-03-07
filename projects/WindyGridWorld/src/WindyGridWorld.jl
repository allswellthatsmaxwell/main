module WindyGridWorld
include("./environment.jl")
# include("./draw.jl")
using .Environment: WindyGridWorldEnv, GridWorld, Policy, reset!,
    Reinforce.finished, Reinforce.actions, Action, Reward, print_value_function, CellIndex,
    WorldState
# using .Draw: draw_image
using Reinforce, Base, ArgParse, Plots

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
    draw_image(env, env.state)
    #for _ in 1:10000
    #    run_one_episode(env, policy, A, monitoring = false)
    #end
    #print_value_function(policy)
    #run_one_episode(env, policy, A, showpath = true)
    
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

function draw_image(env::WindyGridWorldEnv, s::WorldState)
    shapes = []
    row_vec = 1:env.world.rows
    col_vec = 1:env.world.cols
    for row in row_vec
        for col in col_vec
            cell = CellIndex(row, col)
            if s == WorldState(cell)
                shape = "circle"
            elseif cell == env.goal
                shape = "star4"
            else
                shape = "square"
            end
            push!(shapes, shape)
        end
    end
    p = scatter(row_vec, col_vec, lab = shapes, show = false)
    savefig(p, "intermediate/p.png")
end



main()

end

