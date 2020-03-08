module WindyGridWorld
include("./environment.jl")
# include("./draw.jl")
using .Environment: WindyGridWorldEnv, GridWorld, Policy, reset!,
    Reinforce.finished, Reinforce.actions, Action, Reward, print_value_function, CellIndex,
    WorldState
using Reinforce, Base, ArgParse, Makie, CairoMakie, FileIO
using Base.Iterators: repeated

defaults = Dict("rows" => 5, "cols" => 4, "goalrow" => 4, "goalcol" => 3)

function read_arg(arg, parsed_args)
    val = parsed_args[arg]
    if val == nothing     
        return defaults[arg]
    else
        return val
    end
end

function main(rows::Int, cols::Int, goalrow::Int, goalcol::Int)
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

function draw_image(env::WindyGridWorldEnv, s::WorldState)
    scene = Scene(resolution = (1000, 1000))
    grid = repeated(1:env.world.rows, env.world.cols)
    grid = hcat([[1 for i in list] for list in grid]...)
    grid[s.cell.row, s.cell.col] = 2
    grid[env.goal.row, env.goal.col] = 3
    println(grid)
    Makie.heatmap!(scene, grid, linewidth = 1,
                   scale_plot = false, show_axis = false, show = false);
    #scene = Makie.heatmap(1:env.world.rows, 1:env.world.cols, grid,
    #                      scale_plot = false, show_axis = false, show = false)
    outfile = File(format"PNG", "intermediate/scene.png")
    FileIO.save(outfile, scene)
end

function draw_image(env, s)
    makevars() = Dict("x" => [], "y" => [])    
    kinds = ("all", "goal", "current")    
    attrs = Dict([(k, Dict()) for k in kinds])    
    attrs["current"]["shape"] = :circle
    attrs["goal"]["shape"] = :cross
    attrs["all"]["shape"] = :square

    attrs["current"]["color"] = :red
    attrs["goal"]["color"] = :green
    attrs["all"]["color"] = :purple
    
    xs = []
    ys = []
    zs = []
    indices = Dict([(k, makevars()) for k in kinds])
    for row in 1:env.world.rows
        for col in 1:env.world.cols
            cell = CellIndex(row, col)
            if s == WorldState(cell)
                target_kind = "current"                               
            elseif cell == env.goal
                target_kind = "goal"
            else
                target_kind = "all"
            end
            push!(indices[target_kind]["x"], row)
            push!(indices[target_kind]["y"], col)

            push!(xs, row)
            push!(ys, col)
            push!(zs, target_kind)
        end
    end
    println("drawing")
    z = reshape(zs, env.world.rows, env.world.cols)
    for var in (xs, ys, z)
        println(var)
    end
    p = heatmap(xs, ys, z, yflip = true,
                c = cgrad([:red, :blue, :green]))# l = (1, :black),
                #grid = true, axiscolor = nothing, size = (600, 500))
    # p = plot()
    #for kind in kinds
    #    inds = indices[kind]
    #    att = attrs[kind]
    #    scatter!(p, inds["x"], inds["y"],
    #             markershape = att["shape"], color = att["color"],
    #             markersize = 20, show = false);
    #end
    savefig(p, "intermediate/p.html")
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

parsed_args = parse_args(s)    
rows = read_arg("rows", parsed_args)
cols = read_arg("cols", parsed_args)
goalrow = read_arg("goalrow", parsed_args)
goalcol = read_arg("goalcol", parsed_args)

CairoMakie.activate!()
main(rows, cols, goalrow, goalcol)

end

