function test_gui_normalized_adapters_smoke()
%TEST_GUI_NORMALIZED_ADAPTERS_SMOKE Smoke test shared GUI normalization.

fprintf('Running GUI normalized adapters smoke test...\n');

%% Rayleigh-Lamb normalized adapter
rlParams = lamb.models.rayleigh_lamb.rlDefaultParams();
rlParams.fmin = 50;
rlParams.fmax = 250;
rlParams.numFrequencyPoints = 10;
rlParams.frequencySpacing = "linspace";

rlOptions = lamb.models.rayleigh_lamb.rlDefaultOptions();
rlOptions.computeA0 = true;
rlOptions.computeS0 = true;

rlRequest = struct('params', rlParams, 'options', rlOptions);
rlGuiResult = guiRunRayleighLambModel(rlRequest);

assert(isstruct(rlGuiResult), 'Rayleigh-Lamb GUI adapter must return a struct.');
assert(isfield(rlGuiResult, 'branches') && ~isempty(rlGuiResult.branches), ...
    'Rayleigh-Lamb GUI adapter must return non-empty normalized branches.');
assert(hasNormalizedBranch(rlGuiResult, "RayleighLamb", "A0"), ...
    'Rayleigh-Lamb GUI adapter must include normalized A0 branch.');
assert(hasNormalizedBranch(rlGuiResult, "RayleighLamb", "S0"), ...
    'Rayleigh-Lamb GUI adapter must include normalized S0 branch.');
assert(isfield(rlGuiResult.metadata, 'modelResult'), ...
    'Rayleigh-Lamb GUI adapter must preserve the canonical model result.');
assert(isfinite(rlGuiResult.metadata.elapsedSeconds), ...
    'Rayleigh-Lamb GUI adapter must report elapsedSeconds metadata.');

rlRawNormalized = guiBuildModelResultView(rlGuiResult.metadata.modelResult, "testCanonicalRL");
assert(numel(rlRawNormalized.branches) == numel(rlGuiResult.branches), ...
    'Raw Rayleigh-Lamb normalization must preserve normalized branch count.');
assertNormalizedBranches(rlGuiResult.branches);

rlPlotData = guiGetNormalizedBranchPlotData(rlGuiResult.branches(1), "frequency");
assertPlotDataIsValid(rlPlotData, 'Rayleigh-Lamb normalized plot data is invalid.');
rlPlotDataK = guiGetNormalizedBranchPlotData(rlGuiResult.branches(1), "kThickness");
assertPlotDataIsValid(rlPlotDataK, 'Rayleigh-Lamb normalized kThickness plot data is invalid.');

rlBranchTables = guiNormalizedBranchesToTables(rlGuiResult);
assertBranchTablesAreValid(rlBranchTables, 'Rayleigh-Lamb normalized branch tables are invalid.');

%% mRLFE normalized adapter, etaS = 0 elastic limit
[mrlfeOptions, ~] = mrlfeResolveExecutionProfile("A0Like", "Fast", ...
    'Surface', "main", 'EtaS', 0, 'A0Policy', "physicalTail");
mrlfeOptions.branchNames = "A0Like";
mrlfeOptions.mrlfeParams.solveComplexK = false;
mrlfeOptions.mrlfeParams.etaS = 0;
mrlfeOptions.mrlfeParams.etaL = 0;
mrlfeOptions.mrlfeParams.useComplexLambda = false;

mrlfeRequest = struct();
mrlfeRequest.params = rlParams;
mrlfeRequest.options = mrlfeOptions;
mrlfeRequest.mrlfeParams = mrlfeOptions.mrlfeParams;
mrlfeRequest.computeElastic = true;
mrlfeRequest.computeVisco = false;
mrlfeGuiResult = guiRunMRLFEModel(mrlfeRequest);

assert(isstruct(mrlfeGuiResult), 'mRLFE GUI adapter must return a struct.');
assert(hasNormalizedBranch(mrlfeGuiResult, "mRLFERealK", "A0Like"), ...
    'mRLFE GUI adapter must expose the unified real-k A0-like branch.');
assert(~hasNormalizedBranch(mrlfeGuiResult, "RayleighLamb", "A0"), ...
    'mRLFE GUI adapter must hide Rayleigh-Lamb seed branches.');
assert(isfinite(mrlfeGuiResult.metadata.elapsedSeconds), ...
    'mRLFE GUI adapter must report elapsedSeconds metadata.');
assert(mrlfeGuiResult.metadata.seedBranchesHiddenFromPlotSurface, ...
    'mRLFE GUI adapter must report hidden seed branches.');

mrlfeRawNormalized = guiBuildModelResultView( ...
    mrlfeGuiResult.metadata.modelResult, "testCanonicalMRLFE");
assert(hasNormalizedBranch(mrlfeRawNormalized, "mRLFERealK", "A0Like"), ...
    'Canonical mRLFE normalization must include the unified branch.');
assertNormalizedBranches(mrlfeGuiResult.branches);

mrlfePlotData = guiGetNormalizedBranchPlotData(mrlfeGuiResult.branches(1), "frequency");
assertPlotDataIsValid(mrlfePlotData, 'mRLFE normalized plot data is invalid.');

mrlfeBranchTables = guiNormalizedBranchesToTables(mrlfeGuiResult);
assertBranchTablesAreValid(mrlfeBranchTables, 'mRLFE normalized branch tables are invalid.');

%% mRLFE normalized adapter, etaS > 0 viscous case
viscoRequest = mrlfeRequest;
viscoRequest.options.mrlfeParams.etaS = 0.05;
viscoRequest.mrlfeParams = viscoRequest.options.mrlfeParams;
viscoRequest.computeElastic = true;
viscoRequest.computeVisco = true;
viscoGuiResult = guiRunMRLFEModel(viscoRequest);
assert(hasNormalizedBranch(viscoGuiResult, "mRLFERealK", "A0Like"), ...
    'mRLFE GUI adapter must return the unified real-k branch for etaS > 0.');
assert(~hasNormalizedBranch(viscoGuiResult, "RayleighLamb", "A0"), ...
    'mRLFE viscous GUI adapter must hide Rayleigh-Lamb seed branches.');

fprintf('GUI normalized adapters smoke test passed.\n');
end

function tf = hasNormalizedBranch(guiResult, modelName, branchName)
tf = false;
if ~isfield(guiResult, 'branches') || isempty(guiResult.branches)
    return;
end
for i = 1:numel(guiResult.branches)
    branch = guiResult.branches(i);
    if string(branch.modelName) == string(modelName) && ...
            string(branch.branchName) == string(branchName)
        tf = true;
        return;
    end
end
end

function assertNormalizedBranches(branches)
required = {'modelName','rawModelName','branchName','frequency', ...
    'phaseVelocity','wavenumber','kThickness','metadata','diagnostics'};
for i = 1:numel(branches)
    assert(all(isfield(branches(i), required)), ...
        'Normalized branch schema is incomplete.');
    assert(iscolumn(branches(i).frequency));
    assert(iscolumn(branches(i).phaseVelocity));
    assert(iscolumn(branches(i).wavenumber));
    assert(iscolumn(branches(i).kThickness));
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
assert(isstruct(branchTables) && ~isempty(fieldnames(branchTables)), message);
keys = fieldnames(branchTables);
requiredVariables = {'ModelName','BranchName','Frequency_Hz', ...
    'PhaseVelocity_mps','Wavenumber_1_per_m','kThickness'};
for iKey = 1:numel(keys)
    T = branchTables.(keys{iKey});
    assert(istable(T), message);
    for iVar = 1:numel(requiredVariables)
        assert(ismember(requiredVariables{iVar}, T.Properties.VariableNames), message);
    end
    assert(height(T) > 0, message);
end
end
