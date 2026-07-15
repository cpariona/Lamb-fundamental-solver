function problem = mrlfeBuildProblem(configuration)
%MRLFEBUILDPROBLEM Build the internal model-layer problem for mRLFE solving.

frequencyInput = configuration.request.frequency_Hz(:);
[frequencySolve_Hz, frequencyGrid] = mrlfeResolveSolveFrequencyGrid( ...
    frequencyInput, configuration.request.numerics, configuration.numericalPreset);
params = prepareFrequencyParams(configuration.solverParams, frequencySolve_Hz);

seedOptions = buildRayleighLambSeedOptions(configuration.branch);

rawRL = rlComputeFundamentalLambModes(params, seedOptions);

problem = struct();
problem.model = "mrlfe";
problem.branch = configuration.branch;
problem.frequencyRequested_Hz = frequencyInput;
problem.frequencySolve_Hz = frequencySolve_Hz;
problem.frequencyGrid = frequencyGrid;
problem.params = params;
problem.material = rawRL.material;
problem.geometry = rawRL.geometry;
problem.seedModes = rawRL.modes;
problem.rawSeedResult = rawRL;
problem.fluid = configuration.request.fluid;
end

function options = buildRayleighLambSeedOptions(branch)
% Rayleigh-Lamb owns the physical seed solve; mRLFE only selects its branch.
options = rlDefaultOptions("Fast");
options.computeA0 = branch == "A0Like";
options.computeS0 = branch == "S0Like";
options.computeMRLFE = false;
options.computeMRLFERealK = false;
options.computeMRLFEElasticRealK = false;
options.computeMRLFEViscoRealK = false;
options.computeMRLFEComplexK = false;
end

function params = prepareFrequencyParams(params, frequencySolve_Hz)
frequencySolve_Hz = frequencySolve_Hz(:);

params.fmin = frequencySolve_Hz(1);
params.fmax = frequencySolve_Hz(end);
params.numFrequencyPoints = numel(frequencySolve_Hz);
params.frequencySpacing = "explicit";
params.frequencyVector_Hz = frequencySolve_Hz;
end
