% Diagnose Han-style viscoelastic real-k residual landscapes near validity cuts.
%
% Purpose:
%   Determine why Han viscoelastic real-k branches stop returning finite Cp:
%     A) a real-k minimum exists but the tracker misses it;
%     B) the minimum lies outside the usual search range;
%     C) the residual becomes monotonic/edge-dominated;
%     D) real-k is no longer an adequate representation and complex-k is needed.
%
% Model:
%   mRLFEHanViscoRealK
%   lambda real
%   muStar = mu + 1i*omega*etaS
%   k real
%
% Output files:
%   mRLFE_han_visco_residual_landscape_summary.csv
%   mRLFE_han_visco_residual_landscape_samples.csv
%
% Notes:
%   This is a diagnostic script, not a production solver.

startup();

% Representative cases around previously observed validity cuts.
cases = [ ...
    struct('E', 50e3,  'etaS', 0.05, 'branch', "A0Like", 'centerF', 6532.93); ...
    struct('E', 50e3,  'etaS', 0.10, 'branch', "A0Like", 'centerF', 4474.87); ...
    struct('E', 50e3,  'etaS', 0.30, 'branch', "A0Like", 'centerF', 2677.03); ...
    struct('E', 100e3, 'etaS', 0.05, 'branch', "A0Like", 'centerF', 11335.10); ...
    struct('E', 100e3, 'etaS', 0.10, 'branch', "A0Like", 'centerF', 7630.56); ...
    struct('E', 300e3, 'etaS', 0.30, 'branch', "A0Like", 'centerF', 9825.83); ...
    struct('E', 300e3, 'etaS', 1.00, 'branch', "A0Like", 'centerF', 5846.91); ...
    struct('E', 500e3, 'etaS', 1.00, 'branch', "A0Like", 'centerF', 8316.58); ...
    struct('E', 50e3,  'etaS', 0.10, 'branch', "S0Like", 'centerF', 3651.65); ...
    struct('E', 100e3, 'etaS', 0.10, 'branch', "S0Like", 'centerF', 6258.52); ...
    struct('E', 300e3, 'etaS', 1.00, 'branch', "S0Like", 'centerF', 5709.71); ...
    struct('E', 500e3, 'etaS', 1.00, 'branch', "S0Like", 'centerF', 7767.77) ...
];

relativeFrequencyOffsets = [-0.15, -0.05, 0, 0.05, 0.15];
CpScanPoints = 6000;
CpMin = 0.25;
CpMax = 90.0;
edgeGuardPoints = 12;
edgeFraction = 0.01;
monotonicTolerance = 0.02;

paramsBase = defaultParams();
paramsBase.fmin = 500;
paramsBase.fmax = 16000;
paramsBase.numFrequencyPoints = 160;
paramsBase.frequencySpacing = "hybrid";
paramsBase.thickness = 0.5e-3;
paramsBase.nu = 0.4999;
paramsBase.CL = 1500;

optionsBase = defaultOptions("Fast");
optionsBase.computeA0 = true;
optionsBase.computeS0 = true;
optionsBase.computeMRLFERealK = true;
optionsBase.computeMRLFEHanViscoRealK = true;
optionsBase.computeMRLFEComplexK = false;

CpScan = linspace(CpMin, CpMax, CpScanPoints);
summaryRows = [];
sampleRows = [];

fprintf('\nHan viscoelastic real-k residual landscape diagnostic\n');
fprintf('------------------------------------------------------\n');
fprintf('Cp scan: %.4g to %.4g m/s, N = %d\n', CpMin, CpMax, CpScanPoints);
fprintf('Frequency offsets around center: %s\n', mat2str(relativeFrequencyOffsets));

for iCase = 1:numel(cases)
    caseInfo = cases(iCase);
    params = paramsBase;
    params.E = caseInfo.E;
    material = computeMaterial(params);
    geometry = computeGeometry(params);
    geometryPublic = rmfield(geometry, 'halfThickness');

    mrlfeParams = defaultMRLFEParams();
    mrlfeParams.fluidDensity = 1000;
    mrlfeParams.fluidSoundSpeed = 1500;
    mrlfeParams.etaS = caseInfo.etaS;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;
    mrlfeParams.solveComplexK = false;

    options = optionsBase;
    options.mrlfeParams = struct('etaS', caseInfo.etaS, 'etaL', 0, 'useComplexLambda', false);

    fprintf('\nCase %d/%d: %s, E = %.6g kPa, etaS = %.6g Pa*s, centerF = %.6g Hz\n', ...
        iCase, numel(cases), caseInfo.branch, caseInfo.E/1e3, caseInfo.etaS, caseInfo.centerF);

    % Compute current tracked solution once for comparison.
    try
        results = computeFundamentalLambModes(params, options);
        currentBranch = results.models.mRLFEHanViscoRealK.branches.(caseInfo.branch);
    catch ME
        warning('Failed to compute current solution for case %d: %s', iCase, ME.message);
        currentBranch = [];
    end

    frequenciesToScan = caseInfo.centerF * (1 + relativeFrequencyOffsets);
    frequenciesToScan = max(paramsBase.fmin, min(paramsBase.fmax, frequenciesToScan));

    for j = 1:numel(frequenciesToScan)
        frequency = frequenciesToScan(j);
        omega = 2*pi*frequency;
        residual = computeResidualVsCp(CpScan, omega, material, geometryPublic, mrlfeParams);
        landscape = analyzeResidualLandscape(CpScan, residual, edgeGuardPoints, edgeFraction, monotonicTolerance);
        currentCp = interpolateCurrentCp(currentBranch, frequency);
        currentValid = interpolateCurrentValid(currentBranch, frequency);

        row = makeSummaryRow(caseInfo, material, frequency, landscape, currentCp, currentValid, CpMin, CpMax, CpScanPoints);
        summaryRows = [summaryRows; row]; %#ok<AGROW>

        sampleRows = appendSampleRows(sampleRows, caseInfo, material, frequency, CpScan, residual, landscape);

        fprintf('  f = %.6g Hz: global Cp %.6g, residual %.3e, local minima %d, edge=%d, monotonic=%d, current Cp %.6g valid=%d\n', ...
            frequency, landscape.GlobalMinCp, landscape.GlobalMinResidual, landscape.NumLocalMinima, ...
            landscape.GlobalMinNearEdge, landscape.IsApproximatelyMonotonic, currentCp, currentValid);
    end
end

mRLFEHanViscoResidualLandscapeSummary = rowsToTable(summaryRows);
mRLFEHanViscoResidualLandscapeSamples = rowsToTable(sampleRows);

writetable(mRLFEHanViscoResidualLandscapeSummary, 'mRLFE_han_visco_residual_landscape_summary.csv');
writetable(mRLFEHanViscoResidualLandscapeSamples, 'mRLFE_han_visco_residual_landscape_samples.csv');

assignin('base', 'mRLFEHanViscoResidualLandscapeSummary', mRLFEHanViscoResidualLandscapeSummary);
assignin('base', 'mRLFEHanViscoResidualLandscapeSamples', mRLFEHanViscoResidualLandscapeSamples);

fprintf('\nResidual landscape summary\n');
fprintf('--------------------------\n');
if ~isempty(mRLFEHanViscoResidualLandscapeSummary)
    disp(mRLFEHanViscoResidualLandscapeSummary(:, {'Branch','E_kPa','EtaS_Pa_s','Frequency_Hz','CurrentCp','CurrentValid','GlobalMinCp','GlobalMinResidual','BestLocalMinCp','BestLocalMinResidual','NumLocalMinima','GlobalMinNearEdge','IsApproximatelyMonotonic','LikelyInterpretation'}));
end
fprintf('\nWrote:\n');
fprintf('  mRLFE_han_visco_residual_landscape_summary.csv\n');
fprintf('  mRLFE_han_visco_residual_landscape_samples.csv\n');

function residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams)
residual = nan(size(CpScan));
for i = 1:numel(CpScan)
    k = omega / CpScan(i);
    residual(i) = mrlfeResidual(k, omega, material, geometry, mrlfeParams);
end
end

function landscape = analyzeResidualLandscape(CpScan, residual, edgeGuardPoints, edgeFraction, monotonicTolerance)
finiteMask = isfinite(residual);
landscape = struct();
landscape.GlobalMinCp = nan;
landscape.GlobalMinResidual = nan;
landscape.GlobalMinIndex = nan;
landscape.GlobalMinNearEdge = false;
landscape.BestLocalMinCp = nan;
landscape.BestLocalMinResidual = nan;
landscape.NumLocalMinima = 0;
landscape.IsApproximatelyMonotonic = false;
landscape.LeftEdgeResidual = nan;
landscape.RightEdgeResidual = nan;
landscape.ResidualDynamicRange = nan;
landscape.LikelyInterpretation = "no finite residual";

if ~any(finiteMask)
    return;
end

finiteResidual = residual(finiteMask);
finiteCp = CpScan(finiteMask);
[globalMinResidual, localIdx] = min(finiteResidual);
globalCp = finiteCp(localIdx);
finiteIndices = find(finiteMask);
globalIdx = finiteIndices(localIdx);

landscape.GlobalMinCp = globalCp;
landscape.GlobalMinResidual = globalMinResidual;
landscape.GlobalMinIndex = globalIdx;
landscape.LeftEdgeResidual = residual(find(finiteMask, 1, 'first'));
landscape.RightEdgeResidual = residual(find(finiteMask, 1, 'last'));
landscape.ResidualDynamicRange = max(finiteResidual) / max(min(finiteResidual), realmin);

edgeCount = max(edgeGuardPoints, ceil(edgeFraction*numel(CpScan)));
landscape.GlobalMinNearEdge = globalIdx <= edgeCount || globalIdx >= numel(CpScan)-edgeCount+1;

localMinIdx = findLocalMinima(residual, edgeGuardPoints);
landscape.NumLocalMinima = numel(localMinIdx);
if ~isempty(localMinIdx)
    [bestLocalResidual, bestOrder] = min(residual(localMinIdx));
    bestIdx = localMinIdx(bestOrder);
    landscape.BestLocalMinCp = CpScan(bestIdx);
    landscape.BestLocalMinResidual = bestLocalResidual;
end

landscape.IsApproximatelyMonotonic = isApproximatelyMonotonic(finiteResidual, monotonicTolerance);
landscape.LikelyInterpretation = classifyLandscape(landscape);
end

function idx = findLocalMinima(residual, edgeGuardPoints)
idx = [];
firstAllowed = 1 + edgeGuardPoints;
lastAllowed = numel(residual) - edgeGuardPoints;
for i = max(2, firstAllowed):min(numel(residual)-1, lastAllowed)
    if isfinite(residual(i)) && residual(i) < residual(i-1) && residual(i) < residual(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
end

function tf = isApproximatelyMonotonic(y, toleranceFraction)
y = y(:);
y = y(isfinite(y));
if numel(y) < 5
    tf = false;
    return;
end
dy = diff(y);
positiveFraction = sum(dy > 0) / numel(dy);
negativeFraction = sum(dy < 0) / numel(dy);
tf = positiveFraction >= (1 - toleranceFraction) || negativeFraction >= (1 - toleranceFraction);
end

function text = classifyLandscape(landscape)
if ~isfinite(landscape.GlobalMinResidual)
    text = "no finite residual";
elseif landscape.GlobalMinNearEdge && landscape.IsApproximatelyMonotonic
    text = "edge-dominated monotonic residual: expand Cp range or consider complex-k";
elseif landscape.GlobalMinNearEdge
    text = "minimum near Cp scan edge: expand Cp range";
elseif landscape.NumLocalMinima == 0
    text = "no local minimum: real-k residual may be monotonic/flat";
elseif landscape.NumLocalMinima >= 1
    text = "real-k local minimum exists";
else
    text = "undetermined";
end
end

function currentCp = interpolateCurrentCp(branch, frequency)
currentCp = nan;
if isempty(branch) || ~isfield(branch, 'frequency') || ~isfield(branch, 'Cp')
    return;
end
f = branch.frequency(:);
cp = branch.Cp(:);
mask = isfinite(f) & isfinite(cp);
if sum(mask) < 2
    return;
end
if frequency < min(f(mask)) || frequency > max(f(mask))
    return;
end
currentCp = interp1(f(mask), cp(mask), frequency, 'linear', nan);
end

function currentValid = interpolateCurrentValid(branch, frequency)
currentValid = false;
if isempty(branch) || ~isfield(branch, 'frequency') || ~isfield(branch, 'Cp')
    return;
end
if isfield(branch, 'validCp')
    valid = branch.validCp(:);
elseif isfield(branch, 'valid')
    valid = branch.valid(:);
else
    valid = isfinite(branch.Cp(:));
end
f = branch.frequency(:);
mask = isfinite(f);
if ~any(mask)
    return;
end
[~, idx] = min(abs(f(mask) - frequency));
validIdx = find(mask);
currentValid = logical(valid(validIdx(idx)));
end

function row = makeSummaryRow(caseInfo, material, frequency, landscape, currentCp, currentValid, CpMin, CpMax, CpScanPoints)
row = struct();
row.Branch = string(caseInfo.branch);
row.E_kPa = caseInfo.E/1e3;
row.Mu_kPa = material.mu/1e3;
row.CT_m_per_s = material.CT;
row.EtaS_Pa_s = caseInfo.etaS;
row.Frequency_Hz = frequency;
row.CenterFrequency_Hz = caseInfo.centerF;
row.CurrentCp = currentCp;
row.CurrentValid = logical(currentValid);
row.GlobalMinCp = landscape.GlobalMinCp;
row.GlobalMinResidual = landscape.GlobalMinResidual;
row.GlobalMinNearEdge = logical(landscape.GlobalMinNearEdge);
row.BestLocalMinCp = landscape.BestLocalMinCp;
row.BestLocalMinResidual = landscape.BestLocalMinResidual;
row.NumLocalMinima = landscape.NumLocalMinima;
row.IsApproximatelyMonotonic = logical(landscape.IsApproximatelyMonotonic);
row.LeftEdgeResidual = landscape.LeftEdgeResidual;
row.RightEdgeResidual = landscape.RightEdgeResidual;
row.ResidualDynamicRange = landscape.ResidualDynamicRange;
row.CpScanMin = CpMin;
row.CpScanMax = CpMax;
row.CpScanPoints = CpScanPoints;
row.LikelyInterpretation = string(landscape.LikelyInterpretation);
end

function rows = appendSampleRows(rows, caseInfo, material, frequency, CpScan, residual, landscape)
% Store a compact downsampled curve plus special points for later plotting.
numSamples = min(300, numel(CpScan));
sampleIdx = unique(round(linspace(1, numel(CpScan), numSamples)));
specialIdx = landscape.GlobalMinIndex;
if isfinite(specialIdx)
    sampleIdx = unique([sampleIdx(:); specialIdx(:)]);
end
for i = 1:numel(sampleIdx)
    idx = sampleIdx(i);
    row = struct();
    row.Branch = string(caseInfo.branch);
    row.E_kPa = caseInfo.E/1e3;
    row.Mu_kPa = material.mu/1e3;
    row.CT_m_per_s = material.CT;
    row.EtaS_Pa_s = caseInfo.etaS;
    row.Frequency_Hz = frequency;
    row.Cp = CpScan(idx);
    row.Residual = residual(idx);
    row.IsGlobalMinimum = idx == landscape.GlobalMinIndex;
    rows = [rows; row]; %#ok<AGROW>
end
end

function T = rowsToTable(rows)
if isempty(rows)
    T = table();
else
    T = struct2table(rows);
end
end
