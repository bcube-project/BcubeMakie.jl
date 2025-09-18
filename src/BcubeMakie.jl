module BcubeMakie
using Makie
using GeometryBasics
using Bcube
using LinearAlgebra

# General recipe to plot a Bcube Mesh
Makie.@recipe(BcubeMeshPlot) do scene
    Makie.Theme()
end
Makie.plottype(::Bcube.AbstractMesh) = BcubeMeshPlot

# General recipe to plot a Bcube Lazy
Makie.@recipe(BcubeLazyPlot) do scene
    Makie.Theme()
end
Makie.plottype(::Bcube.AbstractMesh, ::Bcube.AbstractLazy) = BcubeLazyPlot

"""
Convert a Bcube mesh to a GeometryBasics mesh.

Warning : we should ensure that all elements are of order <= 1 because
`NgonFace` only supports flat faces.
"""
function _bcube_to_geometry(bmesh::Bcube.AbstractMesh)
    xs = get_coords.(get_nodes(bmesh))
    ps = map(GeometryBasics.Point, xs)

    c2n = Bcube.connectivities_indices(bmesh, :c2n)
    fs = map(c2n) do _c2n
        GeometryBasics.NgonFace(_c2n...)
    end

    @show length(ps)

    GeometryBasics.Mesh(ps, fs)
end

# For Wireframe or Mesh, convert Bcube mesh to a GeometryBasics mesh
function Makie.convert_arguments(
    ::Type{<:Union{Makie.Wireframe, Makie.Mesh}},
    bmesh::Bcube.AbstractMesh,
)
    return (_bcube_to_geometry(bmesh),)
end

function Makie.convert_arguments(
    ::Makie.PointBased,
    bmesh::Bcube.AbstractMesh{N, 1},
) where {N}
    xs = get_coords.(get_nodes(bmesh))
    ps = map(x -> Makie.Point(x..., 0.0), xs)
    return (ps,)
end
function Makie.convert_arguments(::Makie.PointBased, bmesh::Bcube.AbstractMesh)
    xs = get_coords.(get_nodes(bmesh))
    ps = map(x -> Makie.Point(x...), xs)
    return (ps,)
end

# Fallback to `mesh` for meshes of dimension 2 or higher
function Makie.plot!(plot::BcubeMeshPlot{<:Tuple{<:Bcube.AbstractMesh}})
    valid_attributes = Makie.shared_attributes(plot, Makie.Mesh)
    Makie.mesh!(plot, valid_attributes, plot[1])
end

# Fallback to `wireframe` for meshes of dimension 1 because `Makie.mesh` does support 1D mesh
function Makie.plot!(plot::BcubeMeshPlot{<:Tuple{<:Bcube.AbstractMesh{1}}})
    valid_attributes = Makie.shared_attributes(plot, Makie.Wireframe)
    Makie.wireframe!(plot, valid_attributes, plot[1])
end

function Makie.plot!(
    plot::BcubeLazyPlot{<:Tuple{<:Bcube.AbstractMesh, <:Bcube.AbstractLazy}},
)
    bmesh = plot[1]
    u = plot[2]
    scalar_values = @lift begin
        values = var_on_vertices($u, $bmesh)
        if ndims(values) == 1
            return values
        else
            return norm.(eachrow(values))
        end
    end
    # scalar_values = lift(bmesh, u) do (bmesh, u)
    #     values = var_on_vertices(u, bmesh)
    #     if ndims(values) == 1
    #         return values
    #     else
    #         return norm.(eachrow(values))
    #     end
    # end
    valid_attributes = Makie.shared_attributes(plot, Makie.Wireframe)
    Makie.wireframe!(plot, valid_attributes, plot[1])
    valid_attributes = Makie.shared_attributes(plot, Makie.Scatter)
    Makie.scatter!(plot, valid_attributes, plot[1]; color = scalar_values, overdraw = true)
end

end
