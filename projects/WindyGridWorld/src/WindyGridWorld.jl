module WindyGridWorld
include("./environment.jl")
using .Environment: WindyGridWorld, GridWorld, Policy

function main()
    env = WindyGridWorld()
    policy = Policy(0.1, env.world)
    
    println(grid)
    println(env)
    
end

main()

end
