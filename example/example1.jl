module Example1
using Bcube
using BcubeMakie
using GLMakie

bmesh = rectangle_mesh(10, 10)
gmesh = BcubeMakie._bcube_to_geometry(bmesh)
p = wireframe(gmesh)
display(p)
# wireframe(mesh)
# plot(mesh)

end