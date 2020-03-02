module WindyGridWorld
include("./environment.jl")
using .Environment: WindyGridWorldEnv, GridWorld

function main()
    ## this fails because AbstractEnvironment has no zero-arg constructor
    # env = WindyGridWorldEnv()
    grid = GridWorld()
    println(grid)
    
end

main()

end
