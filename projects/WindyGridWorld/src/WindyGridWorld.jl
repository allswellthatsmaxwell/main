module WindyGridWorld
include("./environment.jl")
using .Environment: WindyGridWorldEnv, MustMoveGrid

function main()
    ## this fails because AbstractEnvironment has no zero-arg constructor
    # env = WindyGridWorldEnv()
    grid = MustMoveGrid()
    println(grid)
    
end

main()

end
