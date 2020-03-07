module Draw
# export draw_image, draw_unicode

include("./environment.jl")
using .Environment: WindyGridWorldEnv, GridWorld, WorldState, CellIndex

using Plots



function draw_unicode(env::WindyGridWorldEnv, s::WorldState)        
    for row in 1:env.world.rows
        for col in 1:env.world.cols
            cell = CellIndex(row, col)
            if s == WorldState(cell)
                s = "○"
            elseif cell == env.goal
                s = "✗"
            else
                s = "■"
            end
            print(s)
        end
        println()
    end
    println()
end

end
