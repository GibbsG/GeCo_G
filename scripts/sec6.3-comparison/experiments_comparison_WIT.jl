
function runExperimentWIT(X::DataFrame, p::PLAFProgram, desired_class::Int64, feasibility_check::Bool, dataset_name::String)

    num_changed = Array{Int64,1}()
    feat_changed = Array{BitArray{1},1}()
    distances = Array{Float64,1}()
    correct_outcome = Array{Bool,1}()
    times = Array{Float64,1}()

    ranges = Dict(feature => Float64(maximum(col)-minimum(col)) for (feature, col) in pairs(eachcol(X)))
    num_features = ncol(X)

    predictions = ScikitLearn.predict(classifier, MLJ.matrix(X))

    println("Total number of predictions: $(size(X,1))\n"*
        "Total number of positive predictions $(sum(predictions))\n"*
        "Total number of negative predictions $(size(X,1)-sum(predictions))")

    num_explained = 0
    num_to_explain = 5000
    num_failed_explained = 0

    for i in 1:size(X,1)
        if predictions[i] != desired_class
            (i % 100 == 0) && println("$(@sprintf("%.2f", 100*num_explained/num_to_explain))% through .. ")

            orig_instance = X[i, :]
            time = @elapsed (closest_entity, distance_min) =
                minimumObservableCounterfactual(X, predictions, orig_instance, p;
                    ranges=ranges,
                    num_features=num_features,
                    desired_class=desired_class,
                    check_feasibility=feasibility_check)

            if isnothing(closest_entity)
                # println("Entity $i cannot be explained.")
                num_failed_explained += 1
            else
                changed = []
                for feature in propertynames(orig_instance)
                    push!(changed, orig_instance[feature] != closest_entity[feature])
                end
                push!(num_changed, count(changed))
                push!(feat_changed, changed)
                push!(distances, distance_min)
                push!(times, time)
            end

            num_explained += 1
            (num_explained >= num_to_explain) && break
        end
    end

    file = "scripts/results/wit_exp/$(dataset_name)_wit_mace_experiment_feasible_$(feasibility_check)_local.jld"
    JLD.save(file, "times", times, "dist", distances, "numfeat", num_changed, "feat_changed", feat_changed, "num_failed", num_failed_explained)

    println("
        Average number of features changed: $(mean(num_changed))
        Average distances:                  $(mean(distances))
        Average times:                      $(mean(times))
        Number of failed explanations:      $(num_failed_explained) ($(100*num_failed_explained/num_explained)%)
        Saved to: $file")
end