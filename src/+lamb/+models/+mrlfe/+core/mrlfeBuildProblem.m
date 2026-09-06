function problem = mrlfeBuildProblem(configuration)
%MRLFEBUILDPROBLEM Build the internal model-layer problem for mRLFE solving.

frequencyInput = configuration.request.frequency_Hz(:);
[frequencySolve_Hz, frequencyGrid] = lamb.models.mrlfe.core.mrlfeResolveSolveFrequencyGrid( ...
    frequencyInput, configuration.request.numerics, configuration.numericalPreset);
params = prepareFrequencyParams(configuration.solverParams, frequencySolve_Hz);

problem = struct();
problem.model = "mrlfe";
problem.branch = configuration.branch;
problem.frequencyRequested_Hz = frequencyInput;
problem.frequencySolve_Hz = frequencySolve_Hz;
problem.frequencyGrid = frequencyGrid;
problem.params = params;
problem.material = lamb.elasticity.elasticFromMuNu(params.mu, params.nu, params.rho);
problem.geometry = struct('thickness', params.thickness);
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
