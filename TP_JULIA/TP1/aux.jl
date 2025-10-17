using JuMP
using Gurobi
using Printf 
using Random
using Plots


function read_3d_array(filename, p_max, m_max, n_max)
    # Crée un tableau 3D rempli de zéros
    data_array = zeros(Float64, p_max, m_max, n_max)
    
    # Ouvre le fichier et lit ligne par ligne
    open(filename, "r") do file
        for line in eachline(file)
            # Ignore les lignes vides ou qui ne contiennent pas de chiffres
            if isempty(strip(line)) || !occursin(r"\d", line)
                continue
            end
            
            # Découpe la ligne en mots et convertit en Float/Int
            vals = split(line)
            if length(vals) != 4
                continue  # ignore les lignes mal formées
            end
            
            p, m, n, v = parse.(Float64, vals)
            
            # Stocke la valeur dans le tableau (indices convertis en Int)
            data_array[Int(p), Int(m), Int(n)] = v
        end
    end
    
    return data_array
end

function print_3d_array(array3D, p, m ,n)
    for k in 1:p
        println("Layer $k:")
        for i in 1:m
            for j in 1:n
                @printf("%6.2f ", array3D[k,i,j])  # 6 caractères, 2 décimales
            end
        println()
        println()
        end
    end
end

function print_2D_array(array2D, m, n)
    for i in 1:m
        for j in 1:n
            @printf("%6.d ", array2D[k,i,j])  # 6 caractères, 2 décimales
        end
    end
end 



function generate_cost_grid(grid_rows::Int, grid_cols::Int, num_blocks::Int, cost_range::Tuple{Float64, Float64})
    # Initialize empty grid
    grid = zeros(Float64, grid_rows, grid_cols)
    
    # Create random block divisions
    row_splits = sort(rand(1:grid_rows-1, num_blocks-1))
    col_splits = sort(rand(1:grid_cols-1, num_blocks-1))
    
    # Add edges to the splits
    row_edges = [0; row_splits; grid_rows]
    col_edges = [0; col_splits; grid_cols]
    
    # Fill each block with a random cost
    for i in 1:length(row_edges)-1
        for j in 1:length(col_edges)-1
            cost = rand(cost_range[1]:1.00:cost_range[2])
            grid[(row_edges[i]+1):row_edges[i+1], (col_edges[j]+1):col_edges[j+1]] .= cost
        end
    end
    
    return grid
end

function generate_survival_matrices(p::Int, m::Int, n::Int, q_range::Tuple{Int,Int}, prob_range::Tuple{Float64,Float64})
    matrices = zeros(Float64, p, m, n)
    for k in 1:p
        
        # Randomly choose q for this matrix
        q = rand(q_range[1]:q_range[2])
        
        # Pick q unique positions in the matrix
        positions = randperm(n*m)[1:q]
        
        # Assign random survival probabilities
        for pos in positions
            i = div(pos-1, n) + 1  
            j = mod(pos-1, n) + 1  
            matrices[k, i, j] = rand(prob_range[1]:0.01:prob_range[2])
        end
    end
    
    return matrices
end

function generate_alpha(p, p_range)
    alpha = zeros(Float64, p)
    for i in 1:p
        alpha[i] = rand(p_range[1]:0.01:p_range[2])
    end
    return alpha
end

env = Gurobi.Env()  # create once, prints license message once

function runtime_for_a_given_problem(p, m, n, k, alpha, cost, param_proba )
    #p est le nombre total d'espèces, m est le nombre de ligne de la matrice représentant le parc, 
    #n est le nombre de colonne, k est le nombre d'espèces en danger, alpha,cost et param_proba sont ceux de l'énoncé

    model = Model(() -> Gurobi.Optimizer(env))
    set_optimizer_attribute(model, "OutputFlag", 0)
    @variable(model, x[1:m, 1:n], Bin)
    @variable(model, z[2:m-1, 2:n-1], Bin)
    #Fonction objectif
    @objective(model, Min, sum(x[i,j]*cost[i,j] for i in 1:m, j in 1:n ) )
    #Condition sur les espèces rares
    for l in 1:k
        @constraint(model, sum(z[i,j]*log(1 - param_proba[k,i,j]) for i in 2:m-1, j in 2:n-1) <= log(1 - alpha[k]))
    end
    #Condition sur les espèces communes
    for l in k+1:p
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

    grb = JuMP.backend(model)
    return MOI.get(grb, Gurobi.ModelAttribute("Runtime"))
end