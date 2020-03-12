#!/bin/bash
julia --project=@. src/WindyGridWorld.jl --rows=20 --cols=30 --goalrow=20 --goalcol=30 --episodes=1000 --ptile=0 --draw=false --verbose=true
