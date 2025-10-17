
include("aux.jl")


p = 6 #Nombre d'espèces 
m=10 #Nombre de ligne 
n=10 #Nombre de colonne

param_proba = read_3d_array("reserve_naturelle_ampl.dat", p, m, n)
alphas = [[0.5 0.5 0.5 0.5 0.5 0.5], [0.9 0.9 0.9 0.5 0.5 0.5], [0.5 0.5 0.5 0.9 0.9 0.9], [0.8 0.8 0.8 0.6 0.6 0.6]]
c = 
[
[6,6,6,4,4,4,4,8,8,8],
[6,6,6,4,4,4,4,8,8,8],
[6,6,6,4,4,4,4,8,8,8],
[5,5,5,3,3,3,3,7,7,7],
[5,5,5,3,3,3,3,7,7,7],
[5,5,5,3,3,3,3,7,7,7],
[5,5,5,3,3,3,3,7,7,7],
[4,4,4,6,6,6,6,5,5,5],
[4,4,4,6,6,6,6,5,5,5],
[4,4,4,6,6,6,6,5,5,5],
];

for u in 1:4 
    alpha = alphas[u]
    #Modélisation
    model = Model(Gurobi.Optimizer)
    @variable(model, x[1:m, 1:n], Bin)
    @variable(model, z[2:m-1, 2:n-1], Bin)
    #Fonction objectif
    @objective(model, Min, sum(x[i,j]*c[i][j] for i in 1:m, j in 1:n ) )
    #Condition sur les espèces rares
    for k in 1:3
        @constraint(model, sum(z[i,j]*log(1 - param_proba[k,i,j]) for i in 2:m-1, j in 2:n-1) <= log(1 - alpha[k]))
    end
    #Condition sur les espèces communes
    for k in 4:p
        @constraint(model, sum(x[i,j]*log(1 - param_proba[k,i,j]) for i in 1:m, j in 1:n) <= log(1 - alpha[k]))
    end

    #Condition sur les zones coeurs
    for i in 2:m-1
        for j in 2:n-1
            @constraint(model, 9*z[i,j] <= sum(x[r,s] for r in [i-1, i, i+1], s in [j-1, j, j+1]))
            @constraint(model, z[i,j]>= sum(x[r,s] for r in [i-1, i, i+1], s in [j-1, j, j+1]) - 8)
        end
    end


    optimize!(model)

    grb = backend(model)
    solve_time = MOI.get(grb, Gurobi.ModelAttribute("Runtime"))
    node_count = MOI.get(grb, Gurobi.ModelAttribute("NodeCount"))
    obj_value = objective_value(model)


    open("solution$u.txt", "w") do io
        println(io, "$m $n")  # grid size

        # Write x (protection area)
        for i in 1:m
            for j in 1:n
                print(io, Int(round(value(x[i,j]))), " ")
            end
            println(io)
        end

        # Separator
        println(io, "---")

        # Write z (core zones)
        for i in 2:m-1
            for j in 2:n-1
                print(io, Int(round(value(z[i,j]))), " ")
            end
            println(io)
        end

        # Separator
        println(io, "---")

        # Write survival probabilities
        for k in 1:3
            prob = 1 - prod(1 - param_proba[k,i,j] * value(z[i,j]) for i in 2:m-1, j in 2:n-1)
            println(io, "Species $k survival: ", prob)
        end
        for k in 4:p
            prob = 1 - prod(1 - param_proba[k,i,j] * value(x[i,j]) for i in 1:m, j in 1:n)
            println(io, "Species $k survival: ", prob)
        end
        println(io, "---")
        # solver info
        println(io, "Solve time (s): ", solve_time)
        println(io, "Nodes developed: ", node_count)
        println(io, "Objective value: ", obj_value)
    end
end
