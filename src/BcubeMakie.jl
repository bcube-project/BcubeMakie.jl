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

function MakieCore.convert_arguments(::Type{<:Wireframe}, bmesh::Bcube.AbstractMesh)
    return _bcube_to_geometry(bmesh)
end

# function MakieCore.plot!(plot::Wireframe{<:Tuple{<:Bcube.AbstractMesh}})
#     bmesh = plot[1]
#     plot
# end

end # module BcubeMakie
