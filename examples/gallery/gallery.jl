module Example2
using Bcube
using BcubeMakie
using GLMakie

function run()
    # 1D mesh - scatter
    bmesh = line_mesh(4)
    fig, ax, plt = scatter(bmesh)

    # 1D mesh - lines
    bmesh = line_mesh(4)
    fig, ax, plt = lines(bmesh)

    # 2D mesh - scatter
    bmesh = Bcube.basic_mesh()
    fig, ax, plt = scatter(bmesh)

    # 2D mesh - wireframe and scatter
    bmesh = Bcube.basic_mesh()
    fig, ax, plt = wireframe(bmesh)
    scatter!(plt, bmesh; overdraw = true)

    # 2D mesh and solution
    bmesh = rectangle_mesh(10, 10)
    u = PhysicalFunction(x -> sum(x))
    fig, ax, plt = plot(bmesh, u)
    Colorbar(fig[1, 2], plt)
end

run()

end