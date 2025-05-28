module BcubeMakie
using MakieCore
using GeometryBasics
using Bcube

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

    GeometryBasics.Mesh(ps, fs)
end

# For mesh of dimension 2 and 3, we convert to a GeometryBasics mesh
function MakieCore.convert_arguments(::Type{<:Wireframe}, bmesh::Bcube.AbstractMesh{2})
    return _bcube_to_geometry(bmesh)
end
function MakieCore.convert_arguments(::Type{<:Wireframe}, bmesh::Bcube.AbstractMesh{3})
    return _bcube_to_geometry(bmesh)
end

# Wireframe doesn't support meshes of dimension 1, so we have to specialize
function MakieCore.plot!(plot::Wireframe{<:Tuple{<:Bcube.AbstractMesh{1}}})
    bmesh = plot[1]
    nodes = get_nodes(bmesh)
    x = get_coords.(nodes)
    c2n = Bcube.connectivities_indices(bmesh, :c2n)

end

end # module BcubeMakie
