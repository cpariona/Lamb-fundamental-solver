%TEST_GUI_NORMALIZED_ADAPTERS_SMOKE Smoke tests for GUI normalized adapter outputs.
%
% This test validates the GUI adapter normalization layer independently from
% the interactive app. It intentionally uses the smallest valid frequency grid
% accepted by rlValidateParams so it can be called from run_all_smoke_tests
% without generating figures.

fprintf('Running GUI normalized adapters smoke test...\n');

%% Rayleigh-Lamb normalized adapter
rlParams = rlDefaultParams();
rlParams.fmin = 50;
rlParams.fmax = 250;
rlParams.numFrequencyPoints = 10;
rlParams.frequencySpacing = "linspace";

rlOptions = rlDefaultOptions();
rlOptions.computeA0 = true;
rlOptions.computeS0 = true;
rlOptions.computeMRLFE = false;
rlOptions.computeMRLFERealK = false;

rlRequest = struct();
rlRequest.params = rlParams;
rlRequest.options = rlOptions;
rlGuiResult = guiRunRayleighLambModel(rlRequest);

assert(isstruct(rlGuiResult), 'Rayleigh-Lamb GUI adapter must return a struct.');
assert(isfield(rlGuiResult, 'branches') && ~isempty(rlGuiResult.branches), ...
    'Rayleigh-Lamb GUI adapter must return non-empty normalized branches.');
assert(hasNormalizedBranch(rlGuiResult, "RayleighLamb", "A0"), ...
    'Rayleigh-Lamb GUI adapter must include normalized A0 branch.');
assert(hasNormalizedBranch(rlGuiResult, "RayleighLamb", "S0"), ...
    'Rayleigh-Lamb GUI adapter must include normalized S0 branch.');
assert(isfield(rlGuiResult, 'metadata') && isfield(rlGuiResult.metadata, 'rawResult'), ...
    'Rayleigh-Lamb GUI adapter must preserve rawResult in metadata.');

rlRawNormalized = guiNormalizeRawResult(rlGuiResult.metadata.rawResult, "testRawRL");
assert(numel(rlRawNormalized.branches) == numel(rlGuiResult.branches), ...
    'Raw Rayleigh-Lamb normalization must preserve the normalized branch count.');

rlPlotData = guiGetNormalizedBranchPlotData(rlGuiResult.branches(1), "frequency");
assertPlotDataIsValid(rlPlotData, 'Rayleigh-Lamb normalized plot data is invalid.');
rlPlotDataK = guiGetNormalizedBranchPlotData(rlGuiResult.branches(1), "kThickness");
assertPlotDataIsValid(rlPlotDataK, 'Rayleigh-Lamb normalized kThickness plot data is invalid.');

rlBranchTables = guiNormalizedBranchesToTables(rlGuiResult);
assert(isstruct(rlBranchTables) && ~isempty(fieldnames(rlBranchTables)), ...
    'Rayleigh-Lamb normalized branch table export must return a non-empty struct.');
assertBranchTablesAreValid(rlBranchTables, 'Rayleigh-Lamb normalized branch tables are invalid.');

%% mRLFE normalized adapter, etaS = 0 elastic limit
mrlfeParams = rlParams;
mrlfeOptions = rlOptions;
mrlfeOptions.computeA0 = true;
mrlfeOptions.computeS0 = false;
mrlfeOptions.computeMRLFE = false;
mrlfeOptions.computeMRLFERealK = true;
mrlfeOptions.mrlfeComputeA0Like = true;
mrlfeOptions.mrlfeComputeS0Like = false;
mrlfeOptions.mrlfeParams = defaultMRLFEParams();
mrlfeOptions.mrlfeParams.solveComplexK = false;
mrlfeOptions.mrlfeParams.etaS = 0;
mrlfeOptions.mrlfeParams.etaL = 0;
mrlfeOptions.mrlfeParams.useComplexLambda = false;

mrlfeRequest = struct();
mrlfeRequest.params = mrlfeParams;
mrlfeRequest.options = mrlfeOptions;
mrlfeRequest.mrlfeParams = mrlfeOptions.mrlfeParams;
mrlfeRequest.computeElastic = true;
mrlfeRequest.computeVisco = false;
mrlfeGuiResult = guiRunMRLFEModel(mrlfeRequest);

assert(isstruct(mrlfeGuiResult), 'mRLFE GUI adapter must return a struct.');
assert(isfield(mrlfeGuiResult, 'branches') && ~isempty(mrlfeGuiResult.branches), ...
    'mRLFE GUI adapter must return non-empty normalized branches.');
assert(hasNormalizedBranch(mrlfeGuiResult, "mRLFERealK", "A0Like"), ...
    'mRLFE GUI adapter must expose the unified mRLFE real-k A0-like branch.');
assert(~hasNormalizedBranch(mrlfeGuiResult, "mRLFEElasticRealK", "A0Like"), ...
    'mRLFE GUI adapter must not expose the etaS=0 reference as a separate normalized model.');

mrlfeRawNormalized = guiNormalizeRawResult(mrlfeGuiResult.metadata.rawResult, "testRawMRLFE");
assert(hasNormalizedBranch(mrlfeRawNormalized, "mRLFERealK", "A0Like"), ...
    'Raw mRLFE normalization must include the unified real-k A0-like branch.');

mrlfePlotData = guiGetNormalizedBranchPlotData(mrlfeGuiResult.branches(1), "frequency");
assertPlotDataIsValid(mrlfePlotData, 'mRLFE normalized plot data is invalid.');

mrlfeBranchTables = guiNormalizedBranchesToTables(mrlfeGuiResult);
assert(isstruct(mrlfeBranchTables) && ~isempty(fieldnames(mrlfeBranchTables)), ...
    'mRLFE normalized branch table export must return a non-empty struct.');
assertBranchTablesAreValid(mrlfeBranchTables, 'mRLFE normalized branch tables are invalid.');

%% mRLFE normalized adapter, etaS > 0 viscous case
viscoRequest = mrlfeRequest;
viscoRequest.options.computeMRLFERealK = true;
viscoRequest.options.mrlfeParams.etaS = 0.05;
viscoRequest.mrlfeParams = viscoRequest.options.mrlfeParams;
viscoRequest.computeElastic = true;
viscoRequest.computeVisco = true;
viscoGuiResult = guiRunMRLFEModel(viscoRequest);
assert(hasNormalizedBranch(viscoGuiResult, "mRLFERealK", "A0Like"), ...
    'mRLFE GUI adapter must return the unified real-k branch for etaS > 0.');
assert(~hasNormalizedBranch(viscoGuiResult, "mRLFEViscoRealK", "A0Like"), ...
    'mRLFE GUI adapter must not expose the viscous raw path as a separate normalized model.');

fprintf('GUI normalized adapters smoke test passed.\n');

function tf = hasNormalizedBranch(guiResult, modelName, branchName)
tf = false;
if ~isfield(guiResult, 'branches') || isempty(guiResult.branches)
    return;
end
for i = 1:numel(guiResult.branches)
    branch = guiResult.branches(i);
    if string(branch.modelName) == string(modelName) && string(branch.branchName) == string(branchName)
        tf = true;
        return;
    end
end
end

function assertPlotDataIsValid(plotData, message)
assert(isstruct(plotData), message);
requiredFields = {'x','y','validMask','xLabel','yLabel','displayName'};
for i = 1:numel(requiredFields)
    assert(isfield(plotData, requiredFields{i}), message);
end
assert(isequal(size(plotData.x), size(plotData.y)), message);
assert(isequal(size(plotData.y), size(plotData.validMask)), message);
assert(any(isfinite(plotData.y(:))), message);
end

function assertBranchTablesAreValid(branchTables, message)
keys = fieldnames(branchTables);
assert(~isempty(keys), message);
requiredVariables = {'ModelName','BranchName','Frequency_Hz','PhaseVelocity_mps','Wavenumber_1_per_m','kThickness'};
for iKey = 1:numel(keys)
    T = branchTables.(keys{iKey});
    assert(istable(T), message);
    for iVar = 1:numel(requiredVariables)
        assert(ismember(requiredVariables{iVar}, T.Properties.VariableNames), message);
    end
    assert(height(T) > 0, message);
end
end
