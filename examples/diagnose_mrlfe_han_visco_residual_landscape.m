% Diagnose Han-style viscoelastic real-k residual landscapes near validity cuts.
%
% Purpose:
%   Determine why Han viscoelastic real-k branches stop returning finite Cp:
%     A) a mode-relevant real-k minimum exists but the tracker misses it;
%     B) a mode-relevant minimum disappears near the validity cut;
%     C) the residual becomes dominated by a low-Cp singular/edge valley;
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
%   This is a diagnostic script, not a production solver.  The global minimum
%   of the singular-value residual can fall at unrealistically low Cp.  This
%   diagnostic therefore reports both the global minimum and the best
%   mode-relevant local minimum near the elastic/Han branch reference.

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
physicalCpFloor = 1.0;

% Branch-specific modal windows. A0 can be broad because it is the low-speed
% flexural-like branch. S0 needs a tighter window to avoid mislabeling A0-like
% local minima as S0-relevant minima.
modalWindowA0LowerFactor = 0.35;
modalWindowA0UpperFactor = 2.50;
modalWindowS0LowerFactor = 0.70;
modalWindowS0UpperFactor = 1.40;

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
fprintf('Physical Cp floor for interpretation: %.4g m/s\n', physicalCpFloor);
fprintf('A0 modal window: %.3g to %.3g times modal reference Cp\n', modalWindowA0LowerFactor, modalWindowA0UpperFactor);
fprintf('S0 modal window: %.3g to %.3g times modal reference Cp\n', modalWindowS0LowerFactor, modalWindowS0UpperFactor);
fprintf('Frequency offsets around center: %s\n', mat2str(relativeFrequencyOffsets));

for iCase = 1:numel(cases)
    caseInfo = cases(iCase);
    params = paramsBase;
    params.E = caseInfo.E;
    material = computeMaterial(params);
    geometry = computeGeometry(params);
    geometryPublic = rmfield(geometry, 'halfThickness');
    [modalWindowLowerFactor, modalWindowUpperFactor] = getModalWindowFactors(caseInfo.branch, ...
        modalWindowA0LowerFactor, modalWindowA0UpperFactor, modalWindowS0LowerFactor, modalWindowS0UpperFactor);

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
    fprintf('  Modal window for %s: %.3g to %.3g times modal reference Cp\n', ...
        caseInfo.branch, modalWindowLowerFactor, modalWindowUpperFactor);

    try
        results = computeFundamentalLambModes(params, options);
        currentBranch = results.models.mRLFEHanViscoRealK.branches.(caseInfo.branch);
        elasticBranch = results.models.mRLFEElasticRealK.branches.(caseInfo.branch);
    catch ME
        warning('Failed to compute current solution for case %d: %s', iCase, ME.message);
        currentBranch = [];
        elasticBranch = [];
    end

    frequenciesToScan = caseInfo.centerF * (1 + relativeFrequencyOffsets);
    frequenciesToScan = max(paramsBase.fmin, min(paramsBase.fmax, frequenciesToScan));

    for j = 1:numel(frequenciesToScan)
        frequency = frequenciesToScan(j);
        omega = 2*pi*frequency;
        residual = computeResidualVsCp(CpScan, omega, material, geometryPublic, mrlfeParams);
        currentCp = interpolateCurrentCp(currentBranch, frequency);
        currentValid = interpolateCurrentValid(currentBranch, frequency);
        elasticCp = interpolateCurrentCp(elasticBranch, frequency);
        modalReferenceCp = chooseModalReferenceCp(currentCp, elasticCp);
        landscape = analyzeResidualLandscape(CpScan, residual, edgeGuardPoints, edgeFraction, monotonicTolerance, ...
            modalReferenceCp, physicalCpFloor, modalWindowLowerFactor, modalWindowUpperFactor);

        row = makeSummaryRow(caseInfo, material, frequency, landscape, currentCp, currentValid, elasticCp, CpMin, CpMax, CpScanPoints, modalWindowLowerFactor, modalWindowUpperFactor);
        summaryRows = [summaryRows; row]; %#ok<AGROW>

        sampleRows = appendSampleRows(sampleRows, caseInfo, material, frequency, CpScan, residual, landscape);

        fprintf('  f = %.6g Hz: global Cp %.6g, modal ref Cp %.6g, best modal Cp %.6g, local minima %d, modal minima %d, current Cp %.6g valid=%d, %s\n', ...
            frequency, landscape.GlobalMinCp, landscape.ModalReferenceCp, landscape.BestModalLocalMinCp, ...
            landscape.NumLocalMinima, landscape.NumModalLocalMinima, currentCp, currentValid, landscape.LikelyInterpretation);
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
    disp(mRLFEHanViscoResidualLandscapeSummary(:, {'Branch','E_kPa','EtaS_Pa_s','Frequency_Hz','CurrentCp','CurrentValid','ElasticCp','GlobalMinCp','GlobalMinResidual','BestLocalMinCp','BestLocalMinResidual','BestModalLocalMinCp','BestModalLocalMinResidual','NumLocalMinima','NumModalLocalMinima','ModalWindowLowerFactor','ModalWindowUpperFactor','LowCpEdgeDominates','LikelyInterpretation'}));
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

function [lowerFactor, upperFactor] = getModalWindowFactors(branchName, a0Lower, a0Upper, s0Lower, s0Upper)
switch string(branchName)
    case "S0Like"
        lowerFactor = s0Lower;
        upperFactor = s0Upper;
    otherwise
        lowerFactor = a0Lower;
        upperFactor = a0Upper;
end
end

function modalReferenceCp = chooseModalReferenceCp(currentCp, elasticCp)
if isfinite(currentCp) && currentCp > 0
    modalReferenceCp = currentCp;
elseif isfinite(elasticCp) && elasticCp > 0
    modalReferenceCp = elasticCp;
else
    modalReferenceCp = nan;
end
end

function landscape = analyzeResidualLandscape(CpScan, residual, edgeGuardPoints, edgeFraction, monotonicTolerance, modalReferenceCp, physicalCpFloor, modalWindowLowerFactor, modalWindowUpperFactor)
finiteMask = isfinite(residual);
landscape = struct();
landscape.GlobalMinCp = nan;
landscape.GlobalMinResidual = nan;
landscape.GlobalMinIndex = nan;
landscape.GlobalMinNearEdge = false;
landscape.LowCpEdgeDominates = false;
landscape.BestLocalMinCp = nan;
landscape.BestLocalMinResidual = nan;
landscape.BestModalLocalMinCp = nan;
landscape.BestModalLocalMinResidual = nan;
landscape.NumLocalMinima = 0;
landscape.NumModalLocalMinima = 0;
landscape.ModalReferenceCp = modalReferenceCp;
landscape.ModalWindowMinCp = nan;
landscape.ModalWindowMaxCp = nan;
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
landscape.LowCpEdgeDominates = landscape.GlobalMinNearEdge && globalCp <= max(physicalCpFloor, CpScan(1) + eps);

localMinIdx = findLocalMinima(residual, edgeGuardPoints);
landscape.NumLocalMinima = numel(localMinIdx);
if ~isempty(localMinIdx)
    [bestLocalResidual, bestOrder] = min(residual(localMinIdx));
    bestIdx = localMinIdx(bestOrder);
    landscape.BestLocalMinCp = CpScan(bestIdx);
    landscape.BestLocalMinResidual = bestLocalResidual;
end

if isfinite(modalReferenceCp) && modalReferenceCp > 0
    landscape.ModalWindowMinCp = max(physicalCpFloor, modalWindowLowerFactor * modalReferenceCp);
    landscape.ModalWindowMaxCp = modalWindowUpperFactor * modalReferenceCp;
    modalIdx = localMinIdx(CpScan(localMinIdx) >= landscape.ModalWindowMinCp & CpScan(localMinIdx) <= landscape.ModalWindowMaxCp);
    landscape.NumModalLocalMinima = numel(modalIdx);
    if ~isempty(modalIdx)
        [bestModalResidual, bestOrder] = min(residual(modalIdx));
        bestModalIdx = modalIdx(bestOrder);
        landscape.BestModalLocalMinCp = CpScan(bestModalIdx);
        landscape.BestModalLocalMinResidual = bestModalResidual;
    end
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
elseif landscape.LowCpEdgeDominates && landscape.NumModalLocalMinima > 0
    text = "low-Cp edge valley dominates globally, but a mode-relevant local minimum exists";
elseif landscape.LowCpEdgeDominates && landscape.NumModalLocalMinima == 0
    text = "low-Cp edge valley dominates and no mode-relevant local minimum was found";
elseif landscape.GlobalMinNearEdge && landscape.IsApproximatelyMonotonic
    text = "edge-dominated monotonic residual: expand Cp range or consider complex-k";
elseif landscape.GlobalMinNearEdge
    text = "minimum near Cp scan edge";
elseif landscape.NumModalLocalMinima > 0
    text = "mode-relevant real-k local minimum exists";
elseif landscape.NumLocalMinima > 0
    text = "only off-reference real-k local minima exist";
elseif landscape.NumLocalMinima == 0
    text = "no local minimum: real-k residual may be monotonic/flat";
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
cp = branch.Cp(:);
mask = isfinite(f);
if ~any(mask)
    return;
end
[~, idx] = min(abs(f(mask) - frequency));
validIdx = find(mask);
nearest = validIdx(idx);
currentValid = logical(valid(nearest)) && isfinite(cp(nearest));
end

function row = makeSummaryRow(caseInfo, material, frequency, landscape, currentCp, currentValid, elasticCp, CpMin, CpMax, CpScanPoints, modalWindowLowerFactor, modalWindowUpperFactor)
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
row.ElasticCp = elasticCp;
row.GlobalMinCp = landscape.GlobalMinCp;
row.GlobalMinResidual = landscape.GlobalMinResidual;
row.GlobalMinNearEdge = logical(landscape.GlobalMinNearEdge);
row.LowCpEdgeDominates = logical(landscape.LowCpEdgeDominates);
row.BestLocalMinCp = landscape.BestLocalMinCp;
row.BestLocalMinResidual = landscape.BestLocalMinResidual;
row.BestModalLocalMinCp = landscape.BestModalLocalMinCp;
row.BestModalLocalMinResidual = landscape.BestModalLocalMinResidual;
row.NumLocalMinima = landscape.NumLocalMinima;
row.NumModalLocalMinima = landscape.NumModalLocalMinima;
row.ModalReferenceCp = landscape.ModalReferenceCp;
row.ModalWindowMinCp = landscape.ModalWindowMinCp;
row.ModalWindowMaxCp = landscape.ModalWindowMaxCp;
row.ModalWindowLowerFactor = modalWindowLowerFactor;
row.ModalWindowUpperFactor = modalWindowUpperFactor;
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
    row.IsBestModalLocalMinimum = isfinite(landscape.BestModalLocalMinCp) && abs(CpScan(idx) - landscape.BestModalLocalMinCp) < 0.5*mean(diff(CpScan));
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
