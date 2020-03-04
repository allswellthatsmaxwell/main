module Worlds
export GridWorld, CellIndex, FlatIndex, adjacent

using LightGraphs
NTILES = 40

abstract type Grid end

mutable struct GridWorld <: Grid
    rows::Int64
    cols::Int64
    graph::SimpleGraph
    actions_to_moves::Dict{Integer, Function}
end

function GridWorld(rows::Int64, cols::Int64, graph::SimpleGraph)
    moves = (left, right, up, down)
    actions_to_moves = Dict([(i, fn) for i, fn in enumerate(moves)])
    return GridWorld(rows, cols, graph, actions_to_moves)
    
end

function GridWorld(rows::Int64, cols::Int64, graph::SimpleGraph)
    
    return GridWorld(rows, cols, graph)
end

function GridWorld(rows::Int64, cols::Int64)
    graph = SimpleGraph(rows * cols)
    connect_adjacent(graph, rows, cols)
    return GridWorld(rows, cols, graph)
end

GridWorld(ntiles::Int64) = GridWorld(ntiles ÷ 2, ntiles ÷ 2)
GridWorld() = GridWorld(NTILES)

struct CellIndex
    row::Int64
    col::Int64
end

left(g::GridWorld, c::CellIndex)  = move_if_dest_exists(g, c, CellIndex(c.row, c.col - 1))
right(g::GridWorld, c::CellIndex) = move_if_dest_exists(g, c, CellIndex(c.row, c.col + 1))
up(g::GridWorld, c::CellIndex)    = move_if_dest_exists(g, c, CellIndex(c.row + 1, c.col))
down(g::GridWorld, c::CellIndex)  = move_if_dest_exists(g, c, CellIndex(c.row - 1, c.col))

function exists(g::GridWorld, c::CellIndex)::Bool
    """
    Returns whether c is an existing position in the GridWorld.
    """
    return 0 <= c.row <= g.rows && 0 <= c.col <= g.cols
end

function move_if_dest_exists(g::GridWorld, c::CellIndex,
                             c_new::CellIndex)::CellIndex
    """
    Returns c_new if it exists in the GridWorld; else, returns c.
    """
    if exists(g, c_new)
        return c_new
    else if exists(g, c)            
        return c
    else
        error("source cell index $(c) does not exist in world")
    end
end


FlatIndex = Integer

function adjacent(a::CellIndex, b::CellIndex)::Bool
    adjacent_or_same_col = abs(a.col - b.col) <= 1
    adjacent_or_same_row = abs(a.row - b.row) <= 1
    return adjacent_or_same_row && adjacent_or_same_col
end

function adjacent(rows::Integer, cols::Integer, a::FlatIndex, b::FlatIndex)
    return adjacent(cell_index(rows, cols, a), cell_index(rows, cols, b))
end

adjacent(g::Grid, a::FlatIndex, b::FlatIndex) = adjacent(g.rows, g.cols, a, b)

function cell_index(rows::Integer, cols::Integer, i::FlatIndex)::CellIndex
    """
    returns the CellIndex for a FlatIndex in a grid with the specified
    number of rows and columns.
    """
    return CellIndex(i % rows, i ÷ cols)
end

function flat_index(rows::Integer, cell::CellIndex)::FlatIndex
    """
    returns the FlatIndex for a CellIndex in a grid with the specified
    number of rows.
    """
    return cell.row + rows * cell.col
end

cell_index(g::Grid, i::FlatIndex) = cell_index(g.rows, g.cols, i)
flat_index(g::Grid, cell::CellIndex) = flat_index(g.rows, cell)

function connect_conditionally(g::SimpleGraph, cond::Function)::Nothing
    """
    :param cond: a function Integer -> Integer -> Bool that takes two vertices 
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

function connect_adjacent(g::SimpleGraph, rows::Integer, cols::Integer)::Nothing
    cond(u, v) = adjacent(rows, cols, u, v) 
    connect_conditionally(g, cond)
end

connect_fully(g::SimpleGraph) = connect_conditionally(g, (u, v) -> true)

end
