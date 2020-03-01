module WindyGridWorld
include("./environment.jl")
using .Environment: WindyGridWorldEnv

function main()
    ## this fails because AbstractEnvironment has no zero-arg constructor
    env = WindyGridWorldEnv()
end

main()

end
