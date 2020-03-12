module WindyGridWorld
include("./environment.jl")
# include("./draw.jl")
using .Environment: WindyGridWorldEnv, GridWorld, Policy, reset!,
    Reinforce.finished, Reinforce.actions, Action, Reward, print_value_function,
    CellIndex, FlatIndex, WorldState, ishole

using Reinforce

using ArgParse: ArgParseSettings, @add_arg_table!
using LightGraphs: vertices
# using FileIO: save
using Makie: heatmap!, Scene, record, recordframe!
using CairoMakie: activate!
using Base.Iterators: repeated


defaults = Dict("rows" => 5, "cols" => 4, "episodes" => 1000, "ptile" => 0.0,
                "verbose" => false, "draw" => false)
defaults["goalrow"] = defaults["rows"]
defaults["goalcol"] = defaults["cols"]

function read_arg(arg, parsed_args)
    val = parsed_args[arg]
    if val == nothing     
        return defaults[arg]
    else
        return val
    end
end

function main(rows::Int, cols::Int, goalrow::Int, goalcol::Int, episodes::Int,
              p_tile_removal::Float64, verbose::Bool, draw::Bool)
    env = WindyGridWorldEnv(rows, cols, CellIndex(goalrow, goalcol),
                            p_tile_removal)
    A = Reinforce.actions(false)
    policy = Policy(0.1, 0.05, 1.0, env.world, A)
    if verbose println("Running episodes.") end
    for _ in 1:episodes
        run_one_episode(env, policy, A, monitoring = false)
    end
    if verbose println("Finished running bulk.") end
    ## print_value_function(policy)
    # Environment.save(policy, "intermediate/policy.jld")
    if draw
        route = run_one_episode(env, policy, A, showpath = true)
        if verbose
            println("Got route. It'd $(length(route)) steps long. Plotting...")
        end    
        animate_route(env, route, episodes)
    end
end

function run_one_episode(env::AbstractEnvironment, policy::AbstractPolicy,
                         A::Set{Action}; monitoring = false,
                         showpath = false)::Array{WorldState, 1}
    s = env.state    
    r::Reward = 0.0
    i = 0
    monitoring_freq = 100
    route = [s]
    # if showpath show_position(env, s) end    
    while !Reinforce.finished(env)        
        a = Reinforce.action(policy, r, s, A)
        r, s′ = Reinforce.step!(env, s, a)
        Reinforce.update!(policy, s, a, r, s′, A)
        s = s′
        push!(route, s)
        i += 1
        if monitoring && i % monitoring_freq == 0
            print_value_function(policy)
        end
        # if showpath show_position(env, s′) end
    end
    reset!(env)
    return route
end

function animate_route(env::AbstractEnvironment, route::Array{WorldState, 1},
                       episodes::Int)
    scene = Scene(resolution = (1000, 1000))    
    record(scene, "out/route_$(episodes).mkv") do io
        for s in route
            grid = makegrid(env, s)
            draw_image(scene, grid)
            recordframe!(io)
        end
    end
    println(grid)
end

function draw_image(scene::Scene, grid::Array{Int, 2})
    rows, cols = size(grid)[1], size(grid)[2]
    Makie.heatmap!(scene, 1:rows, 1:cols, grid,
                   linecolor = :white, linewidth = 1,
                   scale_plot = false, show_axis = false, show = false)    
end

function makegrid(env::WindyGridWorldEnv, s::WorldState)::Array{Int, 2}
    """
    Makes a 2D array where the locations of the current, goal, and hole states
    have their own numbers (and everything else has a 4th number).
    """
    grid = repeated(1:env.world.rows, env.world.cols)
    grid = hcat([[1 for i in list] for list in grid]...)
    grid[s.cell.row, s.cell.col] = 2
    grid[env.goal.row, env.goal.col] = 3
    for vertex in vertices(env.world.graph)
        cell = CellIndex(env.world, vertex::FlatIndex)
        if ishole(env.world, cell)
            println("hole!")
            grid[cell.row, cell.col] = 4
        end
    end
    return grid
end                       



s = ArgParseSettings()
@add_arg_table! s begin
    "--rows", "-r"
    help = "Number of rows in the world."
    arg_type = Int

    "--cols", "-c"
    help = "Number of columns in the world."
    arg_type = Int

    "--goalrow"
    help = "row to place the goal at."
    arg_type = Int

    "--goalcol"
    help = "column to place the goal at."
    arg_type = Int

    "--episodes", "-e"
    help = "number of episodes to train with."
    arg_type = Int

    "--ptile"
    help = "probability that any given tile is removed, leaving a hole."
    arg_type = Float64

    "--verbose", "-v"
    arg_type = Bool

    "--draw"
    help = "should a movie of the agent's progress be written to disk?"
    arg_type = Bool
end

parsed_args = parse_args(s)    
rows = read_arg("rows", parsed_args)
cols = read_arg("cols", parsed_args)
goalrow = read_arg("goalrow", parsed_args)
goalcol = read_arg("goalcol", parsed_args)
episodes = read_arg("episodes", parsed_args)
p_tile_removal = read_arg("ptile", parsed_args)
verbose = read_arg("verbose", parsed_args)
draw = read_arg("draw", parsed_args)

CairoMakie.activate!()
main(rows, cols, goalrow, goalcol, episodes, p_tile_removal, verbose,
     draw)

end

