
module Worlds
export GridWorld, CellIndex, FlatIndex, adjacent

import Base: ==
using LightGraphs
NTILES = 40

abstract type World end

mutable struct GridWorld <: World
    rows::Int
    cols::Int
    graph::SimpleGraph
    actions_to_moves::Dict{Int, Function}
    p_tile_removal::Float64
end

function GridWorld(rows::Int, cols::Int, graph::SimpleGraph)
    moves = (left, right, up, down, stay)
    actions_to_moves = Dict([(i, fn) for (i, fn) in enumerate(moves)])
    return GridWorld(rows, cols, graph, actions_to_moves)
end

function GridWorld(rows::Int, cols::Int)
    graph = SimpleGraph(rows * cols)
    connect_adjacent!(graph, rows, cols)    
    return GridWorld(rows, cols, graph)
end

function GridWorld(rows::Int, cols::Int, p_tile_removal::Float64)
    world = GridWorld(rows, cols)
    remove_tiles!(world.graph, p_tile_removal)
    return world
end


GridWorld(ntiles::Int) = GridWorld(ntiles ÷ 2, ntiles ÷ 2)
GridWorld() = GridWorld(NTILES)

FlatIndex = Int

struct CellIndex
    row::Int
    col::Int
end

## show(io::IO, c::CellIndex) = print(io, "($(c.row), $(c.col))")

Base.isequal(c1::CellIndex, c2::CellIndex) = c1 == c2

==(c1::CellIndex, c2::CellIndex) = (c1.row == c2.row) && (c1.col == c2.col)

Base.hash(c::CellIndex, h::UInt) = hash(c.row, h) * hash(c.col, h)

function CellIndex(rows::Int, cols::Int, i::FlatIndex)::CellIndex
    """
    returns the CellIndex for a FlatIndex in a grid with the specified
    number of rows and columns.
    """
    return CellIndex(i % rows, (i ÷ (cols + 1)) + 1)
end

CellIndex(g::GridWorld, i::FlatIndex) = CellIndex(g.rows, g.cols, i)

left(g::GridWorld, c::CellIndex)  = move_if_dest_exists(g, c, CellIndex(c.row, c.col - 1))
right(g::GridWorld, c::CellIndex) = move_if_dest_exists(g, c, CellIndex(c.row, c.col + 1))
up(g::GridWorld, c::CellIndex)    = move_if_dest_exists(g, c, CellIndex(c.row + 1, c.col))
down(g::GridWorld, c::CellIndex)  = move_if_dest_exists(g, c, CellIndex(c.row - 1, c.col))
stay(g::GridWorld, c::CellIndex)  = c

function exists(g::GridWorld, c::CellIndex)::Bool
    """
    Returns whether c is an existing position in the GridWorld.
    """
    return 1 <= c.row <= g.rows && 1 <= c.col <= g.cols
end

function move_if_dest_exists(g::GridWorld, c::CellIndex,
                             c_new::CellIndex)::CellIndex
    """
    Returns c_new if it exists in the GridWorld; else, returns c.
    """
    if exists(g, c_new)
        return c_new
    elseif exists(g, c)
        return c
    else
        error("source cell index $(c) does not exist in world")
    end
end

## TODO: We need to use the graph here, not just assume we're fully connected.
function adjacent(a::CellIndex, b::CellIndex)::Bool
    adjacent_or_same_col = abs(a.col - b.col) <= 1
    adjacent_or_same_row = abs(a.row - b.row) <= 1    
    ## return adjacent_or_same_row && adjacent_or_same_col
    ## TODO: disallows diagonals for now - allow them with another argument
    coldist = abs(a.col - b.col)
    rowdist = abs(a.row - b.row)
    return (rowdist <= 1 && coldist == 0) || (rowdist == 0 && coldist <= 1)
end

function adjacent(rows::Int, cols::Int, a::FlatIndex, b::FlatIndex)
    return adjacent(CellIndex(rows, cols, a), CellIndex(rows, cols, b))
end

adjacent(g::World, a::FlatIndex, b::FlatIndex) = adjacent(g.rows, g.cols, a, b)


function flat_index(rows::Int, cell::CellIndex)::FlatIndex
    """
    returns the FlatIndex for a CellIndex in a grid with the specified
    number of rows.
    """
    return cell.row + rows * (cell.col - 1)
end

flat_index(g::World, cell::CellIndex) = flat_index(g.rows, cell)

function connect_conditionally!(g::SimpleGraph, cond::Function)::Nothing
    """
    :param cond: a function Int -> Int -> Bool that takes two vertices 
    and returns whether they should be connected.
    """    
    for v ∈ vertices(g)
        for u ∈ vertices(g)
            if cond(u, v)
                add_edge!(g, u, v)
            end
        end
    end
end

function connect_adjacent!(g::SimpleGraph, rows::Int, cols::Int)::Nothing
    cond(u, v) = adjacent(rows, cols, u, v) 
    connect_conditionally!(g, cond)
end

function remove_tiles!(g::SimpleGraph, p::Float64)
    """
    Removes vertices at random from a graph.

    :param p: the probability with which each tile is removed.
    """
    for v in vertices(g)
        if rand() < p
            rem_vertex!(g, v)
        end
    end                        
end

connect_fully!(g::SimpleGraph) = connect_conditionally(g, (u, v) -> true)

end
