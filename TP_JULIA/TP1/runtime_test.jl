nb_test = 3
taille_init_grille = 10
taille_max_grille = 100
problem_sizes = taille_init_grille:taille_max_grille
runtime_matrix = zeros(Float64, nb_test, taille_max_grille - taille_init_grille + 1)

for trial in 1:nb_test
    for i in taille_init_grille:taille_max_grille
        t= runtime_for_a_given_problem(
            10, i, i, 5, 
            generate_alpha(10, (0.4, 0.8)), 
            generate_cost_grid(i,i, Int(round(sqrt(i))), (5.0, 12.0)), 
            generate_survival_matrices(10, i,i,( div(i*i,10) , div(i*i,10) + i), (0.3,0.6)))
        runtime_matrix[trial,i - taille_init_grille + 1] = t
    end
end


open("C:\Users\maelv\Desktop\TP_RO\TP1\runtime.txt", "w") do io
        tmp = taille_max_grille - taille_init_grille + 1
        println(io, "$nb_test $tmp")  # grid size

        # Write x (protection area)
        for i in 1:tmp
            for j in 1:nb_test
                print(io, Int(round(value(runtime_matrix[j,i]))), " ")
            end
            println(io)
        end
    end