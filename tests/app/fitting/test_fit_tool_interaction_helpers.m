function test_fit_tool_interaction_helpers()
fprintf('\nRunning FitTool interaction helper test...\n');
fprintf('-----------------------------------------\n');

repoRoot = testRepositoryRoot();
fittingTabPath = fullfile(repoRoot, 'app', 'fitting', 'createFittingTab.m');
oldFittingTabPath = fullfile(repoRoot, 'app', 'createFittingTab.m');
assert(isfile(fittingTabPath), 'createFittingTab must be owned by app/fitting.');
assert(~isfile(oldFittingTabPath), 'The former app-root createFittingTab path must be absent.');
assert(strcmp(which('createFittingTab'), fittingTabPath), ...
    'createFittingTab must resolve uniquely from app/fitting.');

%% Manual data table helpers.
data = [1000, 2.5, 1; 2000, 3.0, 1];
data = guiAppendExperimentalFitRow(data);
assert(size(data, 1) == 3, 'Add row should append exactly one row.');
assert(isequaln(data(end, 1:3), [nan, nan, 1]), 'Added row must be [nan nan 1].');

dataDeleted = guiDeleteExperimentalFitRows(data, [2; 2; 99]);
assert(size(dataDeleted, 1) == 2, 'Delete rows should remove unique valid selected rows.');
assert(isequaln(dataDeleted(2, 1:3), [nan, nan, 1]), 'Delete rows should preserve remaining data order.');

dataUnchanged = guiDeleteExperimentalFitRows(dataDeleted, []);
assert(isequaln(dataUnchanged, dataDeleted), 'Empty selection should not change data.');

metadata = struct('sourceType', "experimental_file", 'fileName', "sample.txt");
metadata = guiMarkExperimentalFitDataEdited(metadata);
assert(metadata.sourceType == "experimental_file", 'Manual edit metadata must preserve sourceType.');
assert(metadata.wasManuallyEdited, 'Manual edit metadata must set wasManuallyEdited.');

%% Axis helpers.
axisState = guiValidateFitAxisLimits([1 8], [100 900]);
assert(axisState.xMode == "manual" && axisState.yMode == "manual", ...
    'Valid manual axis state should use manual modes.');
assertThrows(@()guiValidateFitAxisLimits([8 1], [100 900]), 'guiValidateFitAxisLimits:InvalidXRange');
assertThrows(@()guiValidateFitAxisLimits([1 8], [900 100]), 'guiValidateFitAxisLimits:InvalidYRange');
assertThrows(@()guiValidateFitAxisLimits([1 nan], [100 900]), 'guiValidateFitAxisLimits:NonFinite');

%% Separated fit summary tables and requested solver curve.
trueParams = lamb.models.rayleigh_lamb.rlDefaultParams();
trueParams.mu = 85e3;
frequency_Hz = linspace(1000, 8000, 7).';
options = lamb.models.rayleigh_lamb.rlDefaultOptions("Fast");
CpSynthetic_mps = lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(trueParams, frequency_Hz, "A0", options);

experimental = struct('frequency_Hz', frequency_Hz, ...
    'Cp_mps', CpSynthetic_mps, ...
    'validMask', true(size(frequency_Hz)));

request = guiBuildFitRequest("rayleigh_lamb", ...
    'branchName', "A0", ...
    'experimental', experimental, ...
    'fixedParams', struct('thickness', trueParams.thickness, 'rho', trueParams.rho, 'nu', trueParams.nu), ...
    'freeParams', "mu", ...
    'initialGuess', struct('mu', 60e3), ...
    'bounds', struct('mu', [20e3, 200e3]), ...
    'controls', struct('executionProfile', "Fast"), ...
    'fitOptions', struct('useStandardErrorWeights', false, ...
        'optimizerOptions', optimset('Display', 'off', 'MaxIter', 8, 'MaxFunEvals', 20, 'TolX', 1e-4)));

fitOutput = guiRunFit(request);
normalized = fitOutput.normalized;
assert(isfield(normalized, 'parameterSummaryTable'), 'Normalized output must include parameterSummaryTable.');
assert(isfield(normalized, 'fitQualitySummaryTable'), 'Normalized output must include fitQualitySummaryTable.');
assert(isequaln(normalized.summaryTable, normalized.parameterSummaryTable), ...
    'summaryTable should remain a compatibility alias for parameterSummaryTable.');

parameterSummary = normalized.parameterSummaryTable;
qualitySummary = normalized.fitQualitySummaryTable;
parameterDisplay = guiBuildFitParameterDisplayTable(parameterSummary);
qualityDisplay = guiBuildFitQualityDisplayTable(qualitySummary);
globalMetricColumns = ["RMSE_mps", "MAE_mps", "R2", "AIC", "BIC", "Warning", "Identifiability"];
assert(~any(ismember(globalMetricColumns, string(parameterSummary.Properties.VariableNames))), ...
    'Parameter summary must not repeat global fit metrics.');
assert(all(ismember(["Parameter", "Role", "Value", "Unit", "Initial", "Lower", "Upper"], ...
    string(parameterSummary.Properties.VariableNames))), ...
    'Parameter summary is missing expected parameter columns.');
assert(all(ismember(["RMSE_mps", "MAE_mps", "R2", "AIC", "BIC", "Warning", "Identifiability"], ...
    string(qualitySummary.Properties.VariableNames))), ...
    'Fit quality summary is missing expected global metric columns.');
assert(height(qualitySummary) == 1, 'Fit quality summary should contain one global row.');
assert(height(parameterDisplay) == 1, 'Visible parameter summary should show only the fitted parameter.');
assert(~ismember("Role", string(parameterDisplay.Properties.VariableNames)), ...
    'Visible parameter summary should not show Role when only the fitted parameter is displayed.');
assert(any(string(parameterDisplay.Parameter) == "Shear modulus"), ...
    'Visible parameter summary should show the fitted parameter.');
assert(~any(string(parameterDisplay.Parameter) == "Thickness"), ...
    'Visible parameter summary should not show fixed parameters.');
assert(~any(ismember(["StandardError", "ConfidenceLower", "ConfidenceUpper"], ...
    string(parameterDisplay.Properties.VariableNames))), ...
    'Visible parameter summary should hide unavailable uncertainty columns.');
assert(isequal(string(qualityDisplay.Properties.VariableNames), ["Metric", "Value"]), ...
    'Visible fit quality summary should use Metric/Value columns.');
assert(any(qualityDisplay.Metric == "RMSE [m/s]"), 'Fit quality display should use readable RMSE label.');
assert(any(qualityDisplay.Metric == "R^2"), 'Fit quality display should use readable R2 label.');
assert(~any(qualityDisplay.Metric == "AIC"), 'Fit quality display should hide unavailable AIC.');
assert(~any(qualityDisplay.Metric == "BIC"), 'Fit quality display should hide unavailable BIC.');

fixedRows = string(parameterSummary.Role) == "Fixed";
assert(all(isnan(parameterSummary.Initial(fixedRows))), 'Fixed rows should not repeat fitted initial guesses.');
assert(all(isnan(parameterSummary.Lower(fixedRows))), 'Fixed rows should not repeat lower bounds.');
assert(all(isnan(parameterSummary.Upper(fixedRows))), 'Fixed rows should not repeat upper bounds.');

requestedFrequency_Hz = linspace(1200, 7600, 25).';
requestedCurve = guiEvaluateRequestedFitCurve(fitOutput, requestedFrequency_Hz);
assert(numel(requestedCurve.frequency_Hz) == 25, 'Requested curve should use the requested number of points.');
assert(requestedCurve.modelFamily == "rayleigh_lamb", 'Requested curve should preserve model family.');
assert(requestedCurve.branchName == "A0", 'Requested curve should preserve branch.');
assert(any(requestedCurve.validMask), 'Requested curve should contain valid solver values.');
assert(isfield(requestedCurve, 'elapsedSeconds') && isfinite(requestedCurve.elapsedSeconds), ...
    'Requested curve should record elapsedSeconds.');
assert(contains(requestedCurve.note, "optimizer not rerun"), ...
    'Requested curve note should state that the optimizer was not rerun.');

%% Fitting tab exposes maintained controls.
fig = uifigure('Visible', 'off');
cleanup = onCleanup(@()delete(fig)); %#ok<NASGU>
tabs = uitabgroup(fig);
controls = createFittingTab(tabs, lamb.models.rayleigh_lamb.rlDefaultParams(), struct());
requiredControls = ["addRowButton", "deleteRowButton", "evaluateCurveButton", ...
    "curveMinKHz", "curveMaxKHz", "curvePoints", ...
    "axisXMinKHz", "axisXMaxKHz", "axisYMinMps", "axisYMaxMps", ...
    "applyAxesButton", "autoAxesButton"];
for i = 1:numel(requiredControls)
    assert(isfield(controls, requiredControls(i)), ...
        'createFittingTab missing control %s.', requiredControls(i));
end
assert(strcmp(controls.dataTable.ColumnName{1}, 'Frequency [Hz]'), ...
    'Data table should show readable frequency label.');
assert(strcmp(controls.dataTable.ColumnName{2}, 'Phase speed [m/s]'), ...
    'Data table should show readable phase-speed label.');
assert(strcmp(controls.axisXMinKHz.Value, ''), 'Auto axis mode should not display zero X min.');
assert(strcmp(controls.axisXMaxKHz.Value, ''), 'Auto axis mode should not display zero X max.');
assert(guiFitDisplayLabel("branch", "A0Like") == "A0-like", ...
    'A0Like display label should be readable.');
assert(guiFitDisplayLabel("policy", "physicalTail") == "Physical tail", ...
    'mRLFE A0 policy display label should be readable.');

fprintf('\nFitTool interaction helper test passed.\n');
end

function assertThrows(fcn, expectedId)
try
    fcn();
catch ME
    assert(strcmp(ME.identifier, expectedId), ...
        'Expected error %s but got %s.', expectedId, ME.identifier);
    return;
end
error('Expected error %s was not thrown.', expectedId);
end
