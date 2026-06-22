function sweepOutput = guiRunRLSweep(request)
%GUIRUNRLSWEEP Run a Rayleigh-Lamb one-parameter sweep from SweepTool.

params = request.baseParams;
if ~isfield(params, 'numFrequencyPoints') || isempty(params.numFrequencyPoints)
    params.numFrequencyPoints = "auto";
end
if ~isfield(params, 'frequencySpacing') || isempty(params.frequencySpacing)
    params.frequencySpacing = "hybrid";
end

controls = request.controls;
if ~isfield(controls, 'robustness') || strlength(string(controls.robustness)) == 0
    controls.robustness = "Balanced";
end

options = rlDefaultOptions(string(controls.robustness));
branchName = string(request.branchName);
options.computeA0 = branchName == "A0";
options.computeS0 = branchName == "S0";
if ~(options.computeA0 || options.computeS0)
    error('Unsupported Rayleigh-Lamb branchName. Use A0 or S0.');
end

sweepSpec = struct();
sweepSpec.parameter = string(request.sweepField);
sweepSpec.values = request.sweepValuesDisplay .* request.displayScale;
sweepSpec.label = string(request.sweepLabel);
sweepSpec.units = string(request.displayUnit);
sweepSpec.displayScale = request.displayScale;

modelName = "RayleighLamb";
rawResults = runParametricSweep(params, options, sweepSpec);
summaryTable = summarizeParametricSweepBranch(rawResults, modelName, branchName, 'Print', false);
normalized = guiNormalizeRLSweep(rawResults, summaryTable, request, modelName, branchName);

sweepOutput = struct();
sweepOutput.request = request;
sweepOutput.modelFamily = "rayleigh_lamb";
sweepOutput.modelName = modelName;
sweepOutput.branchName = branchName;
sweepOutput.sweepSpec = sweepSpec;
sweepOutput.rawResults = rawResults;
sweepOutput.summaryTable = summaryTable;
sweepOutput.normalized = normalized;
end
