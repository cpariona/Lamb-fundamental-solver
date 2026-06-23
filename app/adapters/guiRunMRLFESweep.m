function sweepOutput = guiRunMRLFESweep(request)
%GUIRUNMRLFESWEEP Run an mRLFE one-parameter sweep from a GUI request.
%
% The adapter owns mRLFE-specific options, solver calls, and summary generation.
% Display-to-solver conversion is taken from the normalized sweep request so
% future model families can share the same registry/request pattern.

params = request.baseParams;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";

controls = request.controls;
if ~isfield(controls, 'robustness') || strlength(string(controls.robustness)) == 0
    controls.robustness = "Fast";
end

options = rlDefaultOptions(string(controls.robustness));
options.computeMRLFEComplexK = false;
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.fluidDensity = getControlValue(controls, 'fluidDensity', 1000);
options.mrlfeParams.fluidSoundSpeed = getControlValue(controls, 'fluidSoundSpeed', 1500);
options.mrlfeParams.etaS = getControlValue(controls, 'etaS', 0.05);
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;

branchName = string(request.branchName);
options.computeA0 = branchName == "A0Like";
options.computeS0 = branchName == "S0Like";
options.mrlfeComputeA0Like = branchName == "A0Like";
options.mrlfeComputeS0Like = branchName == "S0Like";
options.computeMRLFERealK = true;
options.computeMRLFEElasticRealK = true;
options.computeMRLFEViscoRealK = true;

modelName = "mRLFERealK";
summaryModelName = "mRLFERealK";
[valuesSolver, displayScale, units] = convertRequestDisplayValues(request);

sweepSpec = struct();
sweepSpec.parameter = string(request.sweepField);
sweepSpec.values = valuesSolver;
sweepSpec.label = string(request.sweepLabel);
sweepSpec.units = units;
sweepSpec.displayScale = displayScale;

rawResults = runParametricSweep(params, options, sweepSpec);
summaryTable = summarizeParametricSweepBranch(rawResults, summaryModelName, branchName, 'Print', false);
normalized = guiNormalizeMRLFESweep(rawResults, summaryTable, request, modelName, branchName);

sweepOutput = struct();
sweepOutput.request = request;
sweepOutput.modelFamily = "mrlfe";
sweepOutput.modelName = modelName;
sweepOutput.branchName = branchName;
sweepOutput.sweepSpec = sweepSpec;
sweepOutput.rawResults = rawResults;
sweepOutput.summaryTable = summaryTable;
sweepOutput.normalized = normalized;
end

function value = getControlValue(controls, fieldName, defaultValue)
if isstruct(controls) && isfield(controls, fieldName) && ~isempty(controls.(fieldName))
    value = controls.(fieldName);
else
    value = defaultValue;
end
end

function [valuesSolver, displayScale, units] = convertRequestDisplayValues(request)
displayScale = getRequestField(request, 'displayScale', 1);
units = string(getRequestField(request, 'displayUnit', ""));
valuesSolver = request.sweepValuesDisplay .* displayScale;
end

function value = getRequestField(request, fieldName, defaultValue)
if isstruct(request) && isfield(request, fieldName) && ~isempty(request.(fieldName))
    value = request.(fieldName);
else
    value = defaultValue;
end
end
