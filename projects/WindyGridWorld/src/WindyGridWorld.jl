module WindyGridWorld
include("./environment.jl")
using .Environment: WindyGridWorld, GridWorld

function main()
    ## this fails because AbstractEnvironment has no zero-arg constructor
    env = WindyGridWorld()
    grid = GridWorld()
    println(grid)
    println(env)
    
end

main()

end
