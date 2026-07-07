function audit = auditMRLFESolverRoutes(varargin)
%AUDITMRLFESOLVERROUTES Characterize active mRLFE solver routes without changing them.
%
% audit = auditMRLFESolverRoutes()
% audit = auditMRLFESolverRoutes('Mode', "quick")
% audit = auditMRLFESolverRoutes('Mode', "full", 'OutputFolder', folder)
%
% The audit compares four currently reachable route families:
%   1. Main-GUI adapter route.
%   2. FitTool atlas-first route, including fast_fit_atlas.
%   3. Direct unified-atlas route.
%   4. Legacy computeMRLFE route.
%
% It records route metadata, runtime, valid coverage, continuity, and pairwise
% Cp differences. It does not alter solver defaults or production files.

parser = inputParser;
parser.FunctionName = mfilename;
addParameter(parser, 'Mode', "quick", @(x) any(strcmpi(string(x), ["quick", "full"])));
addParameter(parser, 'OutputFolder', "", @(x) ischar(x) || isstring(x));
addParameter(parser, 'WriteOutputs', true, @(x) islogical(x) && isscalar(x));
parse(parser, varargin{:});

mode = lower(string(parser.Results.Mode));
outputFolder = string(parser.Results.OutputFolder);
writeOutputs = parser.Results.WriteOutputs;

if strlength(outputFolder) == 0
    outputFolder = fullfile(tempdir, 'lamb_fundamental_solver', 'mrlfe_solver_route_audit');
end
if writeOutputs && ~isfolder(outputFolder)
    mkdir(outputFolder);
end

cases = buildAuditCases(mode);
records = repmat(emptyRecord(), 0, 1);
details = struct();

fprintf('\nRunning mRLFE solver-route audit (%s mode)\n', mode);
fprintf('Output folder: %s\n', outputFolder);
fprintf('Cases: %d\n\n', height(cases));

for caseIndex = 1:height(cases)
    caseSpec = table2struct(cases(caseIndex, :));
    caseId = sprintf('%s_etaS_%g_mu_%g_h_%g', ...
        char(caseSpec.branchName), caseSpec.etaS, caseSpec.mu, caseSpec.thickness);
    caseId = matlab.lang.makeValidName(caseId);

    fprintf('[%d/%d] %s, etaS=%g, mu=%g Pa, h=%g m\n', ...
        caseIndex, height(cases), caseSpec.branchName, caseSpec.etaS, ...
        caseSpec.mu, caseSpec.thickness);

    params = buildParams(caseSpec);
    frequency_Hz = linspace(caseSpec.fmin_Hz, caseSpec.fmax_Hz, caseSpec.pointCount).';

    routeOutputs = struct();
    routeOutputs.main_gui = runMainGuiRoute(params, frequency_Hz, caseSpec);
    routeOutputs.fit_fast_atlas = runFitAtlasRoute(params, frequency_Hz, caseSpec);
    routeOutputs.unified_atlas = runUnifiedAtlasRoute(params, frequency_Hz, caseSpec);
    routeOutputs.legacy_compute = runLegacyComputeRoute(params, frequency_Hz, caseSpec);

    routeNames = string(fieldnames(routeOutputs));
    for routeIndex = 1:numel(routeNames)
        routeName = routeNames(routeIndex);
        item = routeOutputs.(routeName);
        records(end + 1, 1) = buildRecord(caseId, caseSpec, routeName, item); %#ok<AGROW>
    end

    details.(caseId) = routeOutputs;
end

routeTable = struct2table(records);
pairwiseTable = buildPairwiseTable(details, cases);

summary = struct();
summary.mode = mode;
summary.createdAt = datetime('now');
summary.caseCount = height(cases);
summary.routeCount = height(routeTable);
summary.errorCount = nnz(strlength(routeTable.errorIdentifier) > 0);
summary.fitFastAtlasErrorCount = nnz(routeTable.routeName == "fit_fast_atlas" & strlength(routeTable.errorIdentifier) > 0);
summary.outputFolder = outputFolder;

audit = struct();
audit.summary = summary;
audit.cases = cases;
audit.routes = routeTable;
audit.pairwise = pairwiseTable;
audit.details = details;

if writeOutputs
    writetable(cases, fullfile(outputFolder, 'mrlfe_solver_route_cases.csv'));
    writetable(routeTable, fullfile(outputFolder, 'mrlfe_solver_route_summary.csv'));
    writetable(pairwiseTable, fullfile(outputFolder, 'mrlfe_solver_route_pairwise.csv'));
    save(fullfile(outputFolder, 'mrlfe_solver_route_audit.mat'), 'audit', '-v7.3');
end

printAuditSummary(audit);
end

function cases = buildAuditCases(mode)
branchName = ["A0Like"; "S0Like"; "A0Like"; "S0Like"];
etaS = [0; 0; 0.05; 0.05];
mu = repmat(75e3, 4, 1);
thickness = repmat(0.5e-3, 4, 1);
fmin_Hz = repmat(1000, 4, 1);
fmax_Hz = repmat(6000, 4, 1);
pointCount = repmat(10, 4, 1);

if mode == "full"
    muGrid = [50e3, 75e3, 158e3, 250e3];
    etaGrid = [0, 0.05, 0.10];
    branchGrid = ["A0Like", "S0Like"];
    rows = numel(muGrid) * numel(etaGrid) * numel(branchGrid);
    branchName = strings(rows, 1);
    etaS = zeros(rows, 1);
    mu = zeros(rows, 1);
    thickness = repmat(0.5e-3, rows, 1);
    fmin_Hz = repmat(1000, rows, 1);
    fmax_Hz = repmat(12000, rows, 1);
    pointCount = repmat(20, rows, 1);
    row = 0;
    for branch = branchGrid
        for eta = etaGrid
            for shear = muGrid
                row = row + 1;
                branchName(row) = branch;
                etaS(row) = eta;
                mu(row) = shear;
            end
        end
    end
end

cases = table(branchName, etaS, mu, thickness, fmin_Hz, fmax_Hz, pointCount);
end

function params = buildParams(caseSpec)
params = mrlfeDefaultSweepParams();
params.mu = caseSpec.mu;
params.etaS = caseSpec.etaS;
params.thickness = caseSpec.thickness;
params.fmin = caseSpec.fmin_Hz;
params.fmax = caseSpec.fmax_Hz;
params.numFrequencyPoints = caseSpec.pointCount;
params.frequencySpacing = "linspace";
end

function item = runMainGuiRoute(params, frequency_Hz, caseSpec)
item = emptyRouteOutput(frequency_Hz);
try
    options = rlDefaultOptions("Fast");
    options.computeA0 = caseSpec.branchName == "A0Like";
    options.computeS0 = caseSpec.branchName == "S0Like";
    options.mrlfeComputeA0Like = caseSpec.branchName == "A0Like";
    options.mrlfeComputeS0Like = caseSpec.branchName == "S0Like";
    options.mrlfeUseUnifiedAtlasRoute = caseSpec.etaS > 0;
    options.mrlfeA0Policy = "adaptivePhysicalTail";
    options.executionProfile = "Fast";
    options.robustness = "Fast";

    mrlfeParams = defaultMRLFEParams();
    mrlfeParams.etaS = caseSpec.etaS;
    mrlfeParams.fluidDensity = 1000;
    mrlfeParams.fluidSoundSpeed = 1500;

    request = struct('params', params, 'options', options, ...
        'mrlfeParams', mrlfeParams, 'computeVisco', caseSpec.etaS > 0);
    t0 = tic;
    result = guiRunMRLFEModel(request);
    item.elapsedSeconds = toc(t0);
    [item.Cp_mps, item.validMask] = extractGuiBranch(result, caseSpec.branchName, frequency_Hz);
    item.actualRoute = string(getNestedField(result, {'metadata', 'mrlfeGuiActualRoute'}, "unknown"));
    item.preset = string(getNestedField(result, {'metadata', 'mrlfeGuiAtlasPreset'}, "unknown"));
    item.fallback = logical(getNestedField(result, {'metadata', 'mrlfeZeroViscosityAdaptiveFallback'}, false));
    item.raw = result;
catch ME
    item = captureError(item, ME);
end
end

function item = runFitAtlasRoute(params, frequency_Hz, caseSpec)
item = emptyRouteOutput(frequency_Hz);
try
    options = mrlfeDefaultSweepOptions(caseSpec.branchName, ...
        'EtaS', caseSpec.etaS, ...
        'UseUnifiedAtlasRoute', true, ...
        'A0Policy', "adaptivePhysicalTail");
    options.mrlfeUseAtlasFitRoute = true;
    options.mrlfeFitAtlasPreset = "fast_fit_atlas";
    t0 = tic;
    [Cp_mps, rawResult] = mrlfeEvaluateFitModel(params, frequency_Hz, caseSpec.branchName, options);
    item.elapsedSeconds = toc(t0);
    item.Cp_mps = Cp_mps(:);
    item.validMask = logical(rawResult.validMask(:));
    item.actualRoute = string(getNestedField(rawResult, {'evaluationPath', 'path'}, "unknown"));
    item.preset = string(getNestedField(rawResult, {'evaluationPath', 'fitAtlasPreset'}, ...
        getNestedField(rawResult, {'fitPerformanceDefaults', 'preset'}, "unknown")));
    item.fallback = false;
    item.raw = rawResult;
catch ME
    item = captureError(item, ME);
end
end

function item = runUnifiedAtlasRoute(params, frequency_Hz, caseSpec)
item = emptyRouteOutput(frequency_Hz);
try
    [rawRL, material, geometry, seedModes] = buildRayleighLambSeed(params, caseSpec.branchName);
    options = mrlfeDefaultSweepOptions(caseSpec.branchName, ...
        'EtaS', caseSpec.etaS, ...
        'UseUnifiedAtlasRoute', true, ...
        'A0Policy', "adaptivePhysicalTail");
    mrlfeParams = options.mrlfeParams;
    mrlfeParams.etaS = caseSpec.etaS;
    t0 = tic;
    result = solveMRLFEAtlasUnified(rawRL.grid.frequency(:), material, geometry, seedModes, mrlfeParams, options);
    item.elapsedSeconds = toc(t0);
    branch = result.branches.(char(caseSpec.branchName));
    [item.Cp_mps, item.validMask] = extractRawBranch(branch, frequency_Hz);
    item.actualRoute = "solveMRLFEAtlasUnified";
    item.preset = "solver_defaults";
    item.fallback = false;
    item.raw = result;
catch ME
    item = captureError(item, ME);
end
end

function item = runLegacyComputeRoute(params, frequency_Hz, caseSpec)
item = emptyRouteOutput(frequency_Hz);
try
    [rawRL, material, geometry, seedModes] = buildRayleighLambSeed(params, caseSpec.branchName);
    options = mrlfeDefaultSweepOptions(caseSpec.branchName, ...
        'EtaS', caseSpec.etaS, ...
        'UseUnifiedAtlasRoute', false, ...
        'A0Policy', "delayedCut");
    options.mrlfeComputeA0Like = caseSpec.branchName == "A0Like";
    options.mrlfeComputeS0Like = caseSpec.branchName == "S0Like";
    mrlfeParams = options.mrlfeParams;
    mrlfeParams.etaS = caseSpec.etaS;
    t0 = tic;
    result = computeMRLFE(rawRL.grid.frequency(:), material, geometry, seedModes, mrlfeParams, options);
    item.elapsedSeconds = toc(t0);
    branch = result.branches.(char(caseSpec.branchName));
    [item.Cp_mps, item.validMask] = extractRawBranch(branch, frequency_Hz);
    item.actualRoute = "computeMRLFE_legacy";
    item.preset = "maintained_default";
    item.fallback = false;
    item.raw = result;
catch ME
    item = captureError(item, ME);
end
end

function [rawRL, material, geometry, seedModes] = buildRayleighLambSeed(params, branchName)
options = rlDefaultOptions("Fast");
options.computeA0 = branchName == "A0Like";
options.computeS0 = branchName == "S0Like";
options.computeMRLFE = false;
options.computeMRLFERealK = false;
options.computeMRLFEElasticRealK = false;
options.computeMRLFEViscoRealK = false;
options.computeMRLFEComplexK = false;
rawRL = rlComputeFundamentalLambModes(params, options);
material = rawRL.material;
geometry = rawRL.geometry;
seedModes = rawRL.modes;
end

function [Cp, valid] = extractGuiBranch(result, branchName, frequency_Hz)
Cp = nan(size(frequency_Hz));
valid = false(size(frequency_Hz));
branches = result.branches;
for index = 1:numel(branches)
    candidateName = string(getFirstField(branches(index), {'name', 'branchName', 'label'}, ""));
    if candidateName == branchName || contains(candidateName, branchName)
        frequency = getFirstField(branches(index), {'frequency_Hz', 'frequency'}, frequency_Hz);
        values = getFirstField(branches(index), {'Cp_mps', 'Cp', 'phaseVelocity'}, nan(size(frequency)));
        mask = getFirstField(branches(index), {'validMask', 'validCp', 'valid'}, isfinite(values));
        Cp = interpFinite(frequency(:), values(:), frequency_Hz);
        valid = interpLogical(frequency(:), logical(mask(:)), frequency_Hz);
        return;
    end
end
error('Audit could not find GUI branch %s.', branchName);
end

function [Cp, valid] = extractRawBranch(branch, frequency_Hz)
frequency = branch.frequency(:);
Cp = interpFinite(frequency, branch.Cp(:), frequency_Hz);
if isfield(branch, 'validCp')
    mask = branch.validCp;
elseif isfield(branch, 'valid')
    mask = branch.valid;
else
    mask = isfinite(branch.Cp);
end
valid = interpLogical(frequency, logical(mask(:)), frequency_Hz);
end

function record = buildRecord(caseId, caseSpec, routeName, item)
record = emptyRecord();
record.caseId = string(caseId);
record.branchName = string(caseSpec.branchName);
record.etaS = caseSpec.etaS;
record.mu_Pa = caseSpec.mu;
record.thickness_m = caseSpec.thickness;
record.routeName = string(routeName);
record.actualRoute = item.actualRoute;
record.preset = item.preset;
record.fallback = item.fallback;
record.elapsedSeconds = item.elapsedSeconds;
record.validCount = nnz(item.validMask & isfinite(item.Cp_mps));
record.pointCount = numel(item.Cp_mps);
record.validFraction = record.validCount / max(record.pointCount, 1);
record.lastValidFrequency_Hz = lastValidFrequency(item.frequency_Hz, item.validMask, item.Cp_mps);
record.maxJumpRelative = maxRelativeJump(item.Cp_mps(item.validMask & isfinite(item.Cp_mps)));
record.errorIdentifier = item.errorIdentifier;
record.errorMessage = item.errorMessage;
end

function pairwise = buildPairwiseTable(details, cases)
rows = repmat(emptyPairwiseRecord(), 0, 1);
caseFields = fieldnames(details);
for caseIndex = 1:numel(caseFields)
    caseId = caseFields{caseIndex};
    outputs = details.(caseId);
    names = string(fieldnames(outputs));
    for leftIndex = 1:numel(names)
        for rightIndex = leftIndex + 1:numel(names)
            left = outputs.(names(leftIndex));
            right = outputs.(names(rightIndex));
            valid = left.validMask & right.validMask & isfinite(left.Cp_mps) & isfinite(right.Cp_mps);
            row = emptyPairwiseRecord();
            row.caseId = string(caseId);
            row.leftRoute = names(leftIndex);
            row.rightRoute = names(rightIndex);
            row.commonValidCount = nnz(valid);
            if any(valid)
                delta = left.Cp_mps(valid) - right.Cp_mps(valid);
                row.maxAbsDifference_mps = max(abs(delta));
                row.rmsDifference_mps = sqrt(mean(delta.^2));
                denominator = max(abs(right.Cp_mps(valid)), eps);
                row.maxRelativeDifference = max(abs(delta) ./ denominator);
            end
            rows(end + 1, 1) = row; %#ok<AGROW>
        end
    end
end
pairwise = struct2table(rows);
if isempty(pairwise)
    pairwise = struct2table(emptyPairwiseRecord());
    pairwise(1, :) = [];
end
end

function item = emptyRouteOutput(frequency_Hz)
item = struct('frequency_Hz', frequency_Hz(:), 'Cp_mps', nan(size(frequency_Hz(:))), ...
    'validMask', false(size(frequency_Hz(:))), 'elapsedSeconds', NaN, ...
    'actualRoute', "unknown", 'preset', "unknown", 'fallback', false, ...
    'errorIdentifier', "", 'errorMessage', "", 'raw', []);
end

function item = captureError(item, ME)
item.errorIdentifier = string(ME.identifier);
item.errorMessage = string(ME.message);
item.actualRoute = "error";
end

function record = emptyRecord()
record = struct('caseId', "", 'branchName', "", 'etaS', NaN, 'mu_Pa', NaN, ...
    'thickness_m', NaN, 'routeName', "", 'actualRoute', "", 'preset', "", ...
    'fallback', false, 'elapsedSeconds', NaN, 'validCount', 0, 'pointCount', 0, ...
    'validFraction', NaN, 'lastValidFrequency_Hz', NaN, 'maxJumpRelative', NaN, ...
    'errorIdentifier', "", 'errorMessage', "");
end

function record = emptyPairwiseRecord()
record = struct('caseId', "", 'leftRoute', "", 'rightRoute', "", ...
    'commonValidCount', 0, 'maxAbsDifference_mps', NaN, ...
    'rmsDifference_mps', NaN, 'maxRelativeDifference', NaN);
end

function value = getNestedField(s, path, defaultValue)
value = defaultValue;
try
    current = s;
    for index = 1:numel(path)
        fieldName = path{index};
        if ~isstruct(current) || ~isfield(current, fieldName)
            return;
        end
        current = current.(fieldName);
    end
    value = current;
catch
    value = defaultValue;
end
end

function value = getFirstField(s, names, defaultValue)
value = defaultValue;
for index = 1:numel(names)
    if isfield(s, names{index})
        value = s.(names{index});
        return;
    end
end
end

function valuesOut = interpFinite(frequencyIn, valuesIn, frequencyOut)
frequencyIn = frequencyIn(:);
valuesIn = valuesIn(:);
frequencyOut = frequencyOut(:);
valid = isfinite(frequencyIn) & isfinite(valuesIn);
if nnz(valid) == 0
    valuesOut = nan(size(frequencyOut));
elseif nnz(valid) == 1
    valuesOut = nan(size(frequencyOut));
    [~, index] = min(abs(frequencyOut - frequencyIn(valid)));
    valuesOut(index) = valuesIn(valid);
else
    valuesOut = interp1(frequencyIn(valid), valuesIn(valid), frequencyOut, 'linear', NaN);
end
end

function valuesOut = interpLogical(frequencyIn, valuesIn, frequencyOut)
frequencyIn = frequencyIn(:);
valuesIn = logical(valuesIn(:));
frequencyOut = frequencyOut(:);
if isempty(frequencyIn) || numel(frequencyIn) ~= numel(valuesIn)
    valuesOut = false(size(frequencyOut));
else
    valuesOut = logical(interp1(frequencyIn, double(valuesIn), frequencyOut, 'nearest', 0));
end
end

function frequency = lastValidFrequency(frequency_Hz, validMask, Cp_mps)
valid = logical(validMask(:)) & isfinite(Cp_mps(:));
if any(valid)
    frequency = max(frequency_Hz(valid));
else
    frequency = NaN;
end
end

function jump = maxRelativeJump(values)
values = values(:);
values = values(isfinite(values) & values > 0);
if numel(values) < 2
    jump = 0;
else
    jump = max(abs(diff(values)) ./ max(abs(values(1:end-1)), eps));
end
end

function printAuditSummary(audit)
fprintf('\nAudit summary\n');
fprintf('-------------\n');
fprintf('Route evaluations: %d\n', height(audit.routes));
fprintf('Errors:            %d\n', audit.summary.errorCount);
fprintf('Fit fast errors:   %d\n', audit.summary.fitFastAtlasErrorCount);
fprintf('\nRoute coverage and runtime:\n');
disp(audit.routes(:, {'caseId', 'routeName', 'actualRoute', 'preset', ...
    'validFraction', 'lastValidFrequency_Hz', 'maxJumpRelative', ...
    'elapsedSeconds', 'fallback', 'errorIdentifier'}));
fprintf('\nPairwise Cp differences:\n');
disp(audit.pairwise);
fprintf('\nSaved under: %s\n', audit.summary.outputFolder);
end
