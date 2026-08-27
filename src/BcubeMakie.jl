module BcubeMakie
using Makie
using GeometryBasics
using Bcube
using LinearAlgebra
using StaticArrays

"""
    bcube_mesh_to_makie_mesh(bmesh::Bcube.AbstractMesh)

Convert a Bcube mesh to a GeometryBasics mesh.

Warning : we should ensure that all elements are of order <= 1 because
`NgonFace` only supports flat faces.
"""
function bcube_mesh_to_makie_mesh(bmesh::Bcube.AbstractMesh)
    xs = get_coords.(get_nodes(bmesh))
    ps = map(GeometryBasics.Point, xs)

    c2n = Bcube.connectivities_indices(bmesh, :c2n)
    fs = map(c2n) do _c2n
        GeometryBasics.NgonFace(_c2n...)
    end

    GeometryBasics.Mesh(ps, fs)
end

# Default plot types (used when the user simply call `plot(...)`)
Makie.plottype(::Bcube.AbstractMesh{1, N}) where {N} = Makie.Lines
Makie.plottype(::Bcube.AbstractMesh) = Makie.Mesh

# For Wireframe or Mesh, convert Bcube mesh to a GeometryBasics mesh
function Makie.convert_arguments(
    p::Type{<:Union{Makie.Wireframe, Makie.Mesh}},
    bmesh::Bcube.AbstractMesh,
)
    println("Converting Bcube mesh to Makie mesh")
    makie_mesh = bcube_mesh_to_makie_mesh(bmesh)
    return convert_arguments(p, makie_mesh)
end

function Makie.convert_arguments(
    p::Makie.PointBased,
    bmesh::Bcube.AbstractMesh{N, 1},
) where {N}
    println("Converting Bcube 1D-mesh to Makie points (with additionnal space dim)")
    xs = get_coords.(get_nodes(bmesh))
    ps = map(x -> Makie.Point(x..., 0.0), xs)
    return convert_arguments(p, ps)
end

function Makie.convert_arguments(p::Makie.PointBased, bmesh::Bcube.AbstractMesh)
    println("Converting Bcube mesh to Makie points")
    xs = get_coords.(get_nodes(bmesh))
    ps = map(x -> Makie.Point(x...), xs)
    return convert_arguments(p, ps)
end

# Special recipe to plot an AbstractLazy on a AbstractMesh. We have to define a custom recipe rather than
# simply implementing a `Makie.convert_arguments` because the AbstractLazy is often used as a color attribute
# (and not as an argument)
Makie.@recipe(BcubeLazyPlot)  do scene
    Makie.Theme()
end
Makie.plottype(::Bcube.AbstractMesh, ::Bcube.AbstractLazy) = BcubeLazyPlot

# This implementation is wrong because it ignores the eventual discontinuous character of the solution
# we should plot cell by cell, without linking the cell with each others
function Makie.plot!(
    plot::BcubeLazyPlot{<:Tuple{<:Bcube.AbstractMesh{1}, <:Bcube.AbstractLazy}},
)
    bmesh = plot[1]
    u = plot[2]

    n_subdivide = @lift begin
        _n = $(plot.attributes[:subdivision])
        if $u isa Bcube.AbstractFEFunction
            _n = max(_n, 2^Bcube.get_degree(Bcube.get_function_space(Bcube.get_fespace($u))))
        end
        return _n
    end

    values_by_cell = @lift begin
        return map(Bcube.DomainIterator(Bcube.CellDomain($bmesh))) do cell
            u_cell = Bcube.materialize($u, cell)
            cnodes = Bcube.nodes(cell)
            ctype = Bcube.celltype(cell)
            cshape = Bcube.shape(ctype)
            ξ1, ξ2 = first.(get_coords(cshape))

            values = zeros($n_subdivide, 2) # (x, u(x))
            for (i, ξ) in enumerate(LinRange(ξ1, ξ2, $n_subdivide))
                _ξ = SA[ξ]
                cPoint = Bcube.CellPoint(_ξ, cell, Bcube.ReferenceDomain())
                values[i, 1] = first(Bcube.mapping(cshape, cnodes, _ξ))
                values[i, 2] = Bcube.materialize(u_cell, cPoint)
            end
            return values
        end
    end
    valid_attributes = Makie.shared_attributes(plot, Lines)
    # WARNING -> this is wrong, we shortcut the Observable, but I don't have a better
    # idea for now
    for values in values_by_cell[]
        Makie.lines!(plot, valid_attributes, view(values, :, 1), view(values, :, 2))
    end
end

function Makie.plot!(
    plot::BcubeLazyPlot{<:Tuple{<:Bcube.AbstractMesh, <:Bcube.AbstractLazy}},
)
    bmesh = plot[1]
    u = plot[2]
    scalar_values = @lift var_on_vertices($u, $bmesh) # warning : `u` must be a scalar field
    valid_attributes = Makie.shared_attributes(plot, Makie.Mesh)
    Makie.mesh!(plot, valid_attributes, plot[1]; color = scalar_values, shading = false)
end

end
