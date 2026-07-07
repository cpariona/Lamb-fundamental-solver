function problem = mrlfeBuildProblem(configuration)
%MRLFEBUILDPROBLEM Build the internal model-layer problem for mRLFE solving.

frequencyInput = configuration.request.frequency_Hz(:);
params = configuration.solverParams;
[params, frequencySolve_Hz] = prepareFrequencyParams(params, frequencyInput);

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
problem.params = params;
problem.material = rawRL.material;
problem.geometry = rawRL.geometry;
problem.seedModes = rawRL.modes;
problem.rawSeedResult = rawRL;
problem.fluid = configuration.request.fluid;
end

function [params, frequencySolve_Hz] = prepareFrequencyParams(params, frequency_Hz)
frequency_Hz = frequency_Hz(:);
[frequencySorted, ~] = sort(frequency_Hz);
if any(abs(frequencySorted - frequency_Hz) > 0)
    error('mrlfe:InvalidFrequencyOrder', 'frequency_Hz must be strictly ascending.');
end

if numel(frequencySorted) == 1
    f0 = frequencySorted(1);
    halfWidth = max(0.05 * f0, 1.0);
    fmin = max(eps(f0), f0 - halfWidth);
    fmax = f0 + halfWidth;
else
    fmin = frequencySorted(1);
    fmax = frequencySorted(end);
end

numFrequencyPoints = max(10, numel(frequencySorted));
frequencySolve_Hz = linspace(fmin, fmax, numFrequencyPoints).';

params.fmin = fmin;
params.fmax = fmax;
params.numFrequencyPoints = numFrequencyPoints;
params.frequencySpacing = "linspace";
end
