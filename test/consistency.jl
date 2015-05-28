# Check consistency with the original WORLD
# Note that all of the results of the original WORLD were dumped as %.16lf
# accuracy on Ubuntu 14.04 64bit machine. g++ v4.8.2 was used to compile the
# WORLD.

info("Check consistency with the original WORLD")

x = vec(readdlm(joinpath(dirname(@__FILE__), "data", "x.txt")))

fs = 16000
period = 5.0
w = World(fs, period)
opt = DioOption(71.0, 800.0, 2, period, 1)

# Fundamental frequency (f0) estimation by DIO
f0, timeaxis = dio(w, x; opt=opt)
f0_org = vec(readdlm(joinpath(dirname(@__FILE__), "data", "f0.txt")))

println("Maximum error in DIO is $(maximum(abs(f0-f0_org)))")
@test length(f0) == length(f0_org)
@test_approx_eq_eps f0 f0_org 1.0e-10

# F0 refienment by StoneMask
f0 = stonemask(w, x, timeaxis, f0)
f0_refined_org = vec(readdlm(joinpath(dirname(@__FILE__), "data", "f0_refined.txt")))

println("Maximum error in StoneMask is $(maximum(abs(f0-f0_refined_org)))")
@test length(f0) == length(f0_refined_org)
@test_approx_eq_eps f0 f0_refined_org 1.0e-10

# Spectral envelope estimation by CheapTrick
spectrogram = cheaptrick(w, x, timeaxis, f0)
spectrogram_org = readdlm(joinpath(dirname(@__FILE__), "data", "spectrogram.txt"))'

println("Maximum error in CheapTrick is $(maximum(abs(spectrogram - spectrogram_org)))")
@test size(spectrogram) == size(spectrogram_org)
@test_approx_eq_eps spectrogram spectrogram_org 1.0e-10

aperiodicity = d4c(w, x, timeaxis, f0)
aperiodicity_org = readdlm(joinpath(dirname(@__FILE__), "data", "aperiodicity.txt"))'
println("Maximum error in D4C is $(maximum(abs(aperiodicity-aperiodicity_org)))")
@test size(aperiodicity) == size(aperiodicity)
@test_approx_eq_eps aperiodicity aperiodicity_org 1.0e-10

# Synthesis
y_length = convert(Int, ((length(f0)-1)*period/1000 * fs) + 1)
y = synthesis(w, f0, spectrogram, aperiodicity, y_length)
y_org = vec(readdlm(joinpath(dirname(@__FILE__), "data", "x_synthesized.txt")))
println("Maximum error in Synthesis is $(maximum(abs(y-y_org)))")
@test length(y) == length(y_org)
@test_approx_eq_eps y y_org 1.0e-10
