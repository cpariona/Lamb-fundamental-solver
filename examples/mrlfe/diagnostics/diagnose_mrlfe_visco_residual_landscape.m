% Diagnose viscoelastic real-k mRLFE residual landscapes near validity cuts.
%
% This diagnostic scans the mRLFE residual over phase velocity Cp and compares
% the global minimum against the best local minimum near the tracked elastic or
% viscoelastic branch reference. It is intended for manual inspection, not as a
% production solver.

startup();

cases = [ ...
    struct('E', 50e3,  'etaS', 0.05, 'branch', "A0Like", 'centerF', 6532.93); ...
    struct('E', 50e3,  'etaS', 0.10, 'branch', "A0Like", 'centerF', 4474.87); ...
    struct('E', 100e3, 'etaS', 0.10, 'branch', "A0Like", 'centerF', 7630.56); ...
    struct('E', 300e3, 'etaS', 1.00, 'branch', "A0Like", 'centerF', 5846.91); ...
    struct('E', 50e3,  'etaS', 0.10, 'branch', "S0Like", 'centerF', 3651.65); ...
    struct('E', 300e3, 'etaS', 1.00, 'branch', "S0Like", 'centerF', 5709.71) ...
];

relativeFrequencyOffsets = [-0.10, 0, 0.10];
CpScan = linspace(0.25, 90.0, 3000);
physicalCpFloor = 1.0;

paramsBase = rlDefaultParams();
paramsBase.fmin = 500;
paramsBase.fmax = 16000;
paramsBase.numFrequencyPoints = 160;
paramsBase.frequencySpacing = "hybrid";
paramsBase.thickness = 0.5e-3;
paramsBase.nu = 0.4999;

optionsBase = rlDefaultOptions("Fast");
optionsBase.computeA0 = true;
optionsBase.computeS0 = true;
optionsBase.computeMRLFERealK = true;
optionsBase.computeMRLFEViscoRealK = true;
optionsBase.computeMRLFEComplexK = false;

summaryRows = [];
sampleRows = [];

fprintf('\nViscoelastic real-k residual landscape diagnostic\n');
fprintf('-------------------------------------------------\n');

for iCase = 1:numel(cases)
    caseInfo = cases(iCase);
    params = setYoungModulusForShearPoisson(paramsBase, caseInfo.E);
    material = rlComputeMaterial(params);
    geometry = rlComputeGeometry(params);
    geometryPublic = rmfield(geometry, 'halfThickness');

    mrlfeParams = defaultMRLFEParams();
    mrlfeParams.fluidDensity = 1000;
    mrlfeParams.fluidSoundSpeed = 1500;
    mrlfeParams.etaS = caseInfo.etaS;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;
    mrlfeParams.solveComplexK = false;

    options = optionsBase;
    options.mrlfeParams = mrlfeParams;

    fprintf('\nCase %d/%d: %s, E = %.6g kPa, mu = %.6g kPa, etaS = %.6g Pa*s\n', ...
        iCase, numel(cases), caseInfo.branch, material.E/1e3, material.mu/1e3, caseInfo.etaS);

    try
        results = rlComputeFundamentalLambModes(params, options);
        viscoBranch = results.models.mRLFEViscoRealK.branches.(caseInfo.branch);
        elasticBranch = results.models.mRLFEElasticRealK.branches.(caseInfo.branch);
    catch ME
        warning('Failed to compute mRLFE branch for case %d: %s', iCase, ME.message);
        continue;
    end

    frequenciesToScan = caseInfo.centerF * (1 + relativeFrequencyOffsets);
    frequenciesToScan = max(paramsBase.fmin, min(paramsBase.fmax, frequenciesToScan));

    for j = 1:numel(frequenciesToScan)
        frequency = frequenciesToScan(j);
        omega = 2*pi*frequency;
        residual = residualVsCp(CpScan, omega, material, geometryPublic, mrlfeParams);
        viscoCp = interpolateCp(viscoBranch, frequency);
        elasticCp = interpolateCp(elasticBranch, frequency);
        referenceCp = chooseReferenceCp(viscoCp, elasticCp);
        branchStatus = classifyBranchStatus(viscoBranch, frequency, viscoCp);
        landscape = summarizeLandscape(CpScan, residual, referenceCp, caseInfo.branch, physicalCpFloor);
        interpretation = interpretLandscape(landscape, branchStatus);

        summaryRows = [summaryRows; makeSummaryRow(caseInfo, material, frequency, viscoCp, elasticCp, branchStatus, landscape, interpretation)]; %#ok<AGROW>
        sampleRows = appendSampleRows(sampleRows, caseInfo, material, frequency, CpScan, residual, landscape); %#ok<AGROW>

        fprintf('  f = %.6g Hz: global Cp %.6g%s, ref Cp %.6g, modal Cp %.6g, modal minima %d, branch %s, %s\n', ...
            frequency, landscape.GlobalMinCp, boundaryLabel(landscape.GlobalMinimumAtLowerBound), ...
            landscape.ReferenceCp, landscape.BestModalLocalMinCp, landscape.NumModalLocalMinima, ...
            branchStatus.Status, interpretation);
    end
end

mRLFEViscoResidualLandscapeSummary = rowsToTable(summaryRows);
mRLFEViscoResidualLandscapeSamples = rowsToTable(sampleRows);

writetable(mRLFEViscoResidualLandscapeSummary, 'mRLFE_visco_residual_landscape_summary.csv');
writetable(mRLFEViscoResidualLandscapeSamples, 'mRLFE_visco_residual_landscape_samples.csv');

assignin('base', 'mRLFEViscoResidualLandscapeSummary', mRLFEViscoResidualLandscapeSummary);
assignin('base', 'mRLFEViscoResidualLandscapeSamples', mRLFEViscoResidualLandscapeSamples);

fprintf('\nWrote:\n');
fprintf('  mRLFE_visco_residual_landscape_summary.csv\n');
fprintf('  mRLFE_visco_residual_landscape_samples.csv\n');

function params = setYoungModulusForShearPoisson(params, youngModulus)
params.E = youngModulus;
params.mu = youngModulus / (2 * (1 + params.nu));
end

function residual = residualVsCp(CpScan, omega, material, geometry, mrlfeParams)
residual = nan(size(CpScan));
for i = 1:numel(CpScan)
    residual(i) = mrlfeResidual(omega / CpScan(i), omega, material, geometry, mrlfeParams);
end
end

function cp = interpolateCp(branch, frequency)
cp = nan;
f = branch.frequency(:);
y = branch.Cp(:);
mask = isfinite(f) & isfinite(y);
if nnz(mask) >= 2 && frequency >= min(f(mask)) && frequency <= max(f(mask))
    cp = interp1(f(mask), y(mask), frequency, 'linear', nan);
end
end

function status = classifyBranchStatus(branch, frequency, cp)
valid = getValidCp(branch);
f = branch.frequency(:);
status = struct();
status.Status = "cut_or_unavailable";
status.IsFiniteCp = isfinite(cp);
status.LastValidFrequency_Hz = nan;
status.DistancePastLastValid_Hz = nan;
if any(valid)
    status.LastValidFrequency_Hz = max(f(valid));
    status.DistancePastLastValid_Hz = frequency - status.LastValidFrequency_Hz;
end
if isfinite(cp) && cp > 0
    status.Status = "available";
elseif isfinite(status.LastValidFrequency_Hz) && frequency > status.LastValidFrequency_Hz
    status.Status = "past_branch_cut";
end
end

function valid = getValidCp(branch)
if isfield(branch, 'validCp')
    valid = branch.validCp;
else
    valid = branch.valid;
end
valid = valid(:) & isfinite(branch.Cp(:));
end

function cp = chooseReferenceCp(viscoCp, elasticCp)
if isfinite(viscoCp) && viscoCp > 0
    cp = viscoCp;
elseif isfinite(elasticCp) && elasticCp > 0
    cp = elasticCp;
else
    cp = nan;
end
end

function landscape = summarizeLandscape(CpScan, residual, referenceCp, branchName, physicalCpFloor)
finiteMask = isfinite(residual);
landscape = struct('GlobalMinCp', nan, 'GlobalMinResidual', nan, 'ReferenceCp', referenceCp, ...
    'BestLocalMinCp', nan, 'BestLocalMinResidual', nan, 'BestModalLocalMinCp', nan, ...
    'BestModalLocalMinResidual', nan, 'NumLocalMinima', 0, 'NumModalLocalMinima', 0, ...
    'ModalWindowMinCp', nan, 'ModalWindowMaxCp', nan, 'GlobalMinIndex', nan, ...
    'GlobalMinimumAtLowerBound', false, 'GlobalMinimumAtUpperBound', false, ...
    'GlobalMinimumBelowPhysicalFloor', false, 'ModalLocalMinimumAvailable', false);
if ~any(finiteMask)
    return;
end
finiteResidual = residual(finiteMask);
finiteCp = CpScan(finiteMask);
[landscape.GlobalMinResidual, idx] = min(finiteResidual);
landscape.GlobalMinCp = finiteCp(idx);
finiteIndices = find(finiteMask);
landscape.GlobalMinIndex = finiteIndices(idx);
landscape.GlobalMinimumAtLowerBound = landscape.GlobalMinIndex == find(finiteMask, 1, 'first');
landscape.GlobalMinimumAtUpperBound = landscape.GlobalMinIndex == find(finiteMask, 1, 'last');
landscape.GlobalMinimumBelowPhysicalFloor = landscape.GlobalMinCp < physicalCpFloor;

localIdx = findLocalMinima(residual, 12);
landscape.NumLocalMinima = numel(localIdx);
if ~isempty(localIdx)
    [landscape.BestLocalMinResidual, bestIdx] = min(residual(localIdx));
    landscape.BestLocalMinCp = CpScan(localIdx(bestIdx));
end

[lowerFactor, upperFactor] = modalWindow(branchName);
if isfinite(referenceCp) && referenceCp > 0
    landscape.ModalWindowMinCp = max(physicalCpFloor, lowerFactor * referenceCp);
    landscape.ModalWindowMaxCp = upperFactor * referenceCp;
    modalIdx = localIdx(CpScan(localIdx) >= landscape.ModalWindowMinCp & CpScan(localIdx) <= landscape.ModalWindowMaxCp);
    landscape.NumModalLocalMinima = numel(modalIdx);
    landscape.ModalLocalMinimumAvailable = ~isempty(modalIdx);
    if ~isempty(modalIdx)
        [landscape.BestModalLocalMinResidual, bestIdx] = min(residual(modalIdx));
        landscape.BestModalLocalMinCp = CpScan(modalIdx(bestIdx));
    end
end
end

function interpretation = interpretLandscape(landscape, branchStatus)
messages = strings(0, 1);
if landscape.GlobalMinimumAtLowerBound
    messages(end+1) = "global minimum at Cp lower scan bound"; %#ok<AGROW>
elseif landscape.GlobalMinimumAtUpperBound
    messages(end+1) = "global minimum at Cp upper scan bound"; %#ok<AGROW>
end
if landscape.GlobalMinimumBelowPhysicalFloor
    messages(end+1) = "global minimum below physical Cp floor"; %#ok<AGROW>
end
if landscape.ModalLocalMinimumAvailable
    messages(end+1) = "modal local minimum available"; %#ok<AGROW>
else
    messages(end+1) = "no modal local minimum in reference window"; %#ok<AGROW>
end
if branchStatus.Status == "past_branch_cut"
    messages(end+1) = "frequency is past tracked branch cut"; %#ok<AGROW>
elseif branchStatus.Status == "cut_or_unavailable"
    messages(end+1) = "tracked visco Cp unavailable"; %#ok<AGROW>
end
interpretation = strjoin(messages, '; ');
end

function label = boundaryLabel(isLowerBound)
if isLowerBound
    label = " (lower-bound)";
else
    label = "";
end
end

function idx = findLocalMinima(residual, edgeGuardPoints)
idx = [];
for i = 1 + edgeGuardPoints:numel(residual) - edgeGuardPoints
    if isfinite(residual(i)) && residual(i) < residual(i-1) && residual(i) < residual(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
end

function [lowerFactor, upperFactor] = modalWindow(branchName)
if string(branchName) == "S0Like"
    lowerFactor = 0.70;
    upperFactor = 1.40;
else
    lowerFactor = 0.35;
    upperFactor = 2.50;
end
end

function row = makeSummaryRow(caseInfo, material, frequency, viscoCp, elasticCp, branchStatus, landscape, interpretation)
row = struct();
row.Branch = string(caseInfo.branch);
row.E_kPa = material.E/1e3;
row.Mu_kPa = material.mu/1e3;
row.CT_m_per_s = material.CT;
row.EtaS_Pa_s = caseInfo.etaS;
row.Frequency_Hz = frequency;
row.ViscoCp = viscoCp;
row.ElasticCp = elasticCp;
row.ViscoBranchStatus = branchStatus.Status;
row.ViscoLastValidFrequency_Hz = branchStatus.LastValidFrequency_Hz;
row.ViscoDistancePastLastValid_Hz = branchStatus.DistancePastLastValid_Hz;
row.GlobalMinCp = landscape.GlobalMinCp;
row.GlobalMinResidual = landscape.GlobalMinResidual;
row.GlobalMinimumAtLowerBound = landscape.GlobalMinimumAtLowerBound;
row.GlobalMinimumAtUpperBound = landscape.GlobalMinimumAtUpperBound;
row.GlobalMinimumBelowPhysicalFloor = landscape.GlobalMinimumBelowPhysicalFloor;
row.ReferenceCp = landscape.ReferenceCp;
row.BestLocalMinCp = landscape.BestLocalMinCp;
row.BestLocalMinResidual = landscape.BestLocalMinResidual;
row.BestModalLocalMinCp = landscape.BestModalLocalMinCp;
row.BestModalLocalMinResidual = landscape.BestModalLocalMinResidual;
row.ModalLocalMinimumAvailable = landscape.ModalLocalMinimumAvailable;
row.NumLocalMinima = landscape.NumLocalMinima;
row.NumModalLocalMinima = landscape.NumModalLocalMinima;
row.ModalWindowMinCp = landscape.ModalWindowMinCp;
row.ModalWindowMaxCp = landscape.ModalWindowMaxCp;
row.Interpretation = string(interpretation);
end

function rows = appendSampleRows(rows, caseInfo, material, frequency, CpScan, residual, landscape)
numSamples = min(250, numel(CpScan));
sampleIdx = unique(round(linspace(1, numel(CpScan), numSamples)));
if isfinite(landscape.GlobalMinIndex)
    sampleIdx = unique([sampleIdx(:); landscape.GlobalMinIndex]);
end
if isfinite(landscape.BestModalLocalMinCp)
    [~, modalIdx] = min(abs(CpScan(:) - landscape.BestModalLocalMinCp));
    sampleIdx = unique([sampleIdx(:); modalIdx]);
end
for i = 1:numel(sampleIdx)
    idx = sampleIdx(i);
    row = struct();
    row.Branch = string(caseInfo.branch);
    row.E_kPa = material.E/1e3;
    row.Mu_kPa = material.mu/1e3;
    row.CT_m_per_s = material.CT;
    row.EtaS_Pa_s = caseInfo.etaS;
    row.Frequency_Hz = frequency;
    row.Cp = CpScan(idx);
    row.Residual = residual(idx);
    row.IsGlobalMinimum = idx == landscape.GlobalMinIndex;
    row.IsBestModalLocalMinimum = isfinite(landscape.BestModalLocalMinCp) && abs(CpScan(idx) - landscape.BestModalLocalMinCp) < mean(diff(CpScan));
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
