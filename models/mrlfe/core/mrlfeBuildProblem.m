function problem = mrlfeBuildProblem(configuration)
%MRLFEBUILDPROBLEM Build the internal model-layer problem for mRLFE solving.

frequencyInput = configuration.request.frequency_Hz(:);
[frequencySolve_Hz, frequencyGrid] = mrlfeResolveSolveFrequencyGrid( ...
    frequencyInput, configuration.request.numerics, configuration.numericalPreset);
params = prepareFrequencyParams(configuration.solverParams, frequencySolve_Hz);

seedOptions = rlDefaultOptions("Fast");
seedOptions.computeA0 = configuration.branch == "A0Like";
seedOptions.computeS0 = configuration.branch == "S0Like";
seedOptions.computeMRLFE = false;
seedOptions.computeMRLFERealK = false;
seedOptions.computeMRLFEElasticRealK = false;
seedOptions.computeMRLFEViscoRealK = false;
seedOptions.computeMRLFEComplexK = false;

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

function params = prepareFrequencyParams(params, frequencySolve_Hz)
frequencySolve_Hz = frequencySolve_Hz(:);

params.fmin = frequencySolve_Hz(1);
params.fmax = frequencySolve_Hz(end);
params.numFrequencyPoints = numel(frequencySolve_Hz);
params.frequencySpacing = "explicit";
params.frequencyVector_Hz = frequencySolve_Hz;
end
