
using Pkg; Pkg.activate(".")
using GeCo

using Printf, DataFrames
import Dates, JLD

include("experiments_comparison_MACE.jl")
include("experiments_comparison_WIT.jl")
include("experiments_comparison_CERT.jl")
include("experiments_comparison_SimCF.jl")

for dataset in ["adult", "credit"]
    include("../$dataset/$(dataset)_setup_MACE.jl")

    Xcopy = DataFrame(X)

    runExperimentMACE(Xcopy, p, 1, dataset)

    Xcopy = DataFrame(X)

    runExperimentCERT(Xcopy, p, 1, dataset)

    Xcopy = DataFrame(X)

    runExperimentWIT(Xcopy, p, 1, true, dataset)

    Xcopy = DataFrame(X)

    runExperimentSimCF(Xcopy, p, 1, dataset)
end
