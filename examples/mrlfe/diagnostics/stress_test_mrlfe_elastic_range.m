% Stress-test elastic real-k mRLFE stability over a practical corneal range.
%
% This diagnostic focuses on the elastic/fluid-loaded model with etaS = 0.
% It is intended to check whether A0-like and S0-like branches remain stable
% up to 16 kHz over a broad equivalent Young's modulus range.
%
% Notes:
%   - E is swept directly because the GUI/material input is E, nu, rho.
%   - For nearly incompressible materials, mu ~= E/(2*(1+nu)) ~= E/3.
%   - The upper bound 1500 kPa is included as an extended diagnostic range.
%   - SafeFmax_Hz is defined as the frequency before the first valid Cp jump
%     exceeding largeJumpThreshold.

startup();

EValues = [50e3, 75e3, 100e3, 150e3, 225e3, 300e3, 400e3, 500e3, ...
           750e3, 1000e3, 1500e3]; % [Pa]
largeJumpThreshold = 0.15;

paramsBase = rlDefaultParams();
paramsBase.fmin = 500;
paramsBase.fmax = 16000;
paramsBase.numFrequencyPoints = 160;
paramsBase.frequencySpacing = "hybrid";
paramsBase.thickness = 0.5e-3;
paramsBase.nu = 0.4999;
paramsBase.CL = 1500;

optionsBase = rlDefaultOptions("Fast");
optionsBase.computeA0 = true;
optionsBase.computeS0 = true;
optionsBase.computeMRLFERealK = true;
optionsBase.computeMRLFEHanViscoRealK = false;
optionsBase.computeMRLFEComplexK = false;

summaryRows = [];
resultsByE = cell(size(EValues));

fprintf('\nmRLFE elastic real-k stability sweep\n');
fprintf('-----------------------------------\n');
fprintf('Frequency range: %.0f to %.0f Hz\n', paramsBase.fmin, paramsBase.fmax);
fprintf('Thickness: %.4g mm\n', paramsBase.thickness*1e3);
fprintf('E values: %.3g to %.3g kPa (%d cases)\n', min(EValues)/1e3, max(EValues)/1e3, numel(EValues));
fprintf('Large-jump threshold for safe fmax: %.3g\n', largeJumpThreshold);

for iE = 1:numel(EValues)
    params = paramsBase;
    params.E = EValues(iE);
    material = rlComputeMaterial(params);

    fprintf('\nE = %.6g kPa, mu = %.6g kPa, CT = %.6g m/s\n', ...
        params.E/1e3, material.mu/1e3, material.CT);

    try
        results = rlComputeFundamentalLambModes(params, optionsBase);
        resultsByE{iE} = results;
        branches = results.models.mRLFEElasticRealK.branches;
        rowA0 = printBranchSummary(branches, 'A0Like', params, material, largeJumpThreshold);
        rowS0 = printBranchSummary(branches, 'S0Like', params, material, largeJumpThreshold);
        summaryRows = [summaryRows; rowA0; rowS0]; %#ok<AGROW>
    catch ME
        fprintf('  ERROR: %s\n', ME.message);
        summaryRows = [summaryRows; makeFailedRow('A0Like', params, material, ME.message)]; %#ok<AGROW>
        summaryRows = [summaryRows; makeFailedRow('S0Like', params, material, ME.message)]; %#ok<AGROW>
    end
end

if isempty(summaryRows)
    mRLFEElasticRangeStabilitySummary = table();
else
    mRLFEElasticRangeStabilitySummary = struct2table(summaryRows);
end

writetable(mRLFEElasticRangeStabilitySummary, 'mRLFE_elastic_range_stability_summary.csv');
assignin('base', 'mRLFEElasticRangeStabilityResults', resultsByE);
assignin('base', 'mRLFEElasticRangeStabilitySummary', mRLFEElasticRangeStabilitySummary);
assignin('base', 'mRLFEElasticRangeStabilityEValues', EValues);
assignin('base', 'mRLFEElasticRangeStabilityLargeJumpThreshold', largeJumpThreshold);

fprintf('\nElastic range stability summary\n');
fprintf('-------------------------------\n');
if ~isempty(mRLFEElasticRangeStabilitySummary)
    disp(mRLFEElasticRangeStabilitySummary(:, {'Branch','E_kPa','Mu_kPa','ValidPoints','TotalPoints','ValidFmax_Hz','SafeFmax_Hz','MaxResidual','MaxRelativeCpJump','FirstLargeJumpRelative','HasWarning'}));
end
fprintf('\nWrote mRLFE_elastic_range_stability_summary.csv\n');

% Plot Cp curves for visual inspection.
figure;
hold on;
for iE = 1:numel(EValues)
    if isempty(resultsByE{iE})
        continue;
    end
    branch = resultsByE{iE}.models.mRLFEElasticRealK.branches.A0Like;
    [frequency, CpPlot] = branchPlotData(branch);
    plot(frequency, CpPlot, 'LineWidth', 1.2, 'DisplayName', sprintf('E = %.0f kPa', EValues(iE)/1e3));
end
grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('mRLFE elastic real-k A0-like stability sweep');
legend('Location', 'best');
hold off;

figure;
hold on;
for iE = 1:numel(EValues)
    if isempty(resultsByE{iE})
        continue;
    end
    branch = resultsByE{iE}.models.mRLFEElasticRealK.branches.S0Like;
    [frequency, CpPlot] = branchPlotData(branch);
    plot(frequency, CpPlot, 'LineWidth', 1.2, 'DisplayName', sprintf('E = %.0f kPa', EValues(iE)/1e3));
end
grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('mRLFE elastic real-k S0-like stability sweep');
legend('Location', 'best');
hold off;

function row = printBranchSummary(branches, branchName, params, material, largeJumpThreshold)
row = makeEmptyRow(branchName, params, material);
row.LargeJumpThreshold = largeJumpThreshold;
if ~isfield(branches, branchName)
    row.HasWarning = true;
    row.WarningText = "branch not available";
    fprintf('  %s: not available\n', branchName);
    return;
end
branch = branches.(branchName);
valid = getValidCp(branch);
row.ValidPoints = sum(valid);
row.TotalPoints = numel(branch.Cp);
row.ValidFraction = row.ValidPoints / max(row.TotalPoints, 1);

fprintf('  %s valid: %d / %d\n', branchName, row.ValidPoints, row.TotalPoints);
if any(valid)
    cpValid = branch.Cp(valid);
    fValid = branch.frequency(valid);
    row.MinCp = min(cpValid);
    row.MaxCp = max(cpValid);
    row.ValidFmin_Hz = min(fValid);
    row.ValidFmax_Hz = max(fValid);
    row.FirstValidFrequency_Hz = fValid(1);
    row.LastValidFrequency_Hz = fValid(end);
    jumpInfo = computeJumpDiagnostics(branch, valid, largeJumpThreshold);
    row.MaxRelativeCpJump = jumpInfo.MaxRelativeCpJump;
    row.FrequencyBeforeMaxJump_Hz = jumpInfo.FrequencyBeforeMaxJump_Hz;
    row.FrequencyAfterMaxJump_Hz = jumpInfo.FrequencyAfterMaxJump_Hz;
    row.CpBeforeMaxJump = jumpInfo.CpBeforeMaxJump;
    row.CpAfterMaxJump = jumpInfo.CpAfterMaxJump;
    row.FirstLargeJumpRelative = jumpInfo.FirstLargeJumpRelative;
    row.FrequencyBeforeFirstLargeJump_Hz = jumpInfo.FrequencyBeforeFirstLargeJump_Hz;
    row.FrequencyAfterFirstLargeJump_Hz = jumpInfo.FrequencyAfterFirstLargeJump_Hz;
    row.CpBeforeFirstLargeJump = jumpInfo.CpBeforeFirstLargeJump;
    row.CpAfterFirstLargeJump = jumpInfo.CpAfterFirstLargeJump;
    row.SafeFmax_Hz = jumpInfo.SafeFmax_Hz;
    fprintf('  %s Cp: %.6g to %.6g m/s\n', branchName, row.MinCp, row.MaxCp);
    fprintf('  %s valid frequency range: %.6g to %.6g Hz; last valid %.6g Hz\n', ...
        branchName, row.ValidFmin_Hz, row.ValidFmax_Hz, row.LastValidFrequency_Hz);
    fprintf('  %s max relative Cp jump: %.3g\n', branchName, row.MaxRelativeCpJump);
    if isfinite(row.FirstLargeJumpRelative)
        fprintf('  %s first jump > %.3g: %.3g at %.6g -> %.6g Hz; safe fmax %.6g Hz\n', ...
            branchName, largeJumpThreshold, row.FirstLargeJumpRelative, ...
            row.FrequencyBeforeFirstLargeJump_Hz, row.FrequencyAfterFirstLargeJump_Hz, row.SafeFmax_Hz);
    else
        fprintf('  %s safe fmax by jump threshold: %.6g Hz\n', branchName, row.SafeFmax_Hz);
    end
else
    row.HasWarning = true;
    row.WarningText = "no valid Cp points";
    fprintf('  %s valid frequency range: none\n', branchName);
end

if any(isfinite(branch.residual))
    row.MaxResidual = max(branch.residual(isfinite(branch.residual)));
    fprintf('  %s max residual: %.3e\n', branchName, row.MaxResidual);
end

warnings = strings(0,1);
if row.ValidFraction < 0.98
    warnings(end+1) = "valid fraction < 0.98"; %#ok<AGROW>
end
if isfinite(row.ValidFmax_Hz) && row.ValidFmax_Hz < params.fmax
    warnings(end+1) = "does not reach fmax"; %#ok<AGROW>
end
if isfinite(row.MaxRelativeCpJump) && row.MaxRelativeCpJump > 0.20
    warnings(end+1) = "max Cp jump > 20%"; %#ok<AGROW>
end
if isfinite(row.FirstLargeJumpRelative)
    warnings(end+1) = "contains jump above safe threshold"; %#ok<AGROW>
end
if isfinite(row.MaxResidual) && row.MaxResidual > 1e-3
    warnings(end+1) = "max residual > 1e-3"; %#ok<AGROW>
end
if ~isempty(warnings)
    row.HasWarning = true;
    row.WarningText = strjoin(warnings, '; ');
    fprintf('  %s warning: %s\n', branchName, row.WarningText);
end
end

function row = makeFailedRow(branchName, params, material, message)
row = makeEmptyRow(branchName, params, material);
row.HasWarning = true;
row.WarningText = "solver error";
row.ErrorMessage = string(message);
end

function row = makeEmptyRow(branchName, params, material)
row = struct();
row.Branch = string(branchName);
row.E_kPa = params.E / 1e3;
row.Mu_kPa = material.mu / 1e3;
row.CT_m_per_s = material.CT;
row.Thickness_mm = params.thickness * 1e3;
row.FmaxTarget_Hz = params.fmax;
row.ValidPoints = 0;
row.TotalPoints = 0;
row.ValidFraction = 0;
row.ValidFmin_Hz = nan;
row.ValidFmax_Hz = nan;
row.FirstValidFrequency_Hz = nan;
row.LastValidFrequency_Hz = nan;
row.SafeFmax_Hz = nan;
row.LargeJumpThreshold = nan;
row.MinCp = nan;
row.MaxCp = nan;
row.MaxResidual = nan;
row.MaxRelativeCpJump = nan;
row.FrequencyBeforeMaxJump_Hz = nan;
row.FrequencyAfterMaxJump_Hz = nan;
row.CpBeforeMaxJump = nan;
row.CpAfterMaxJump = nan;
row.FirstLargeJumpRelative = nan;
row.FrequencyBeforeFirstLargeJump_Hz = nan;
row.FrequencyAfterFirstLargeJump_Hz = nan;
row.CpBeforeFirstLargeJump = nan;
row.CpAfterFirstLargeJump = nan;
row.HasWarning = false;
row.WarningText = "";
row.ErrorMessage = "";
end

function jumpInfo = computeJumpDiagnostics(branch, valid, largeJumpThreshold)
f = branch.frequency(:);
cp = branch.Cp(:);
idx = find(valid(:) & isfinite(cp) & isfinite(f));

jumpInfo = struct();
jumpInfo.MaxRelativeCpJump = 0;
jumpInfo.FrequencyBeforeMaxJump_Hz = nan;
jumpInfo.FrequencyAfterMaxJump_Hz = nan;
jumpInfo.CpBeforeMaxJump = nan;
jumpInfo.CpAfterMaxJump = nan;
jumpInfo.FirstLargeJumpRelative = nan;
jumpInfo.FrequencyBeforeFirstLargeJump_Hz = nan;
jumpInfo.FrequencyAfterFirstLargeJump_Hz = nan;
jumpInfo.CpBeforeFirstLargeJump = nan;
jumpInfo.CpAfterFirstLargeJump = nan;
jumpInfo.SafeFmax_Hz = nan;

if isempty(idx)
    return;
end
jumpInfo.SafeFmax_Hz = f(idx(end));
if numel(idx) < 2
    return;
end
relJump = abs(diff(cp(idx))) ./ max(abs(cp(idx(1:end-1))), eps);
[maxJump, maxLocalIdx] = max(relJump);
jumpInfo.MaxRelativeCpJump = maxJump;
iBeforeMax = idx(maxLocalIdx);
iAfterMax = idx(maxLocalIdx+1);
jumpInfo.FrequencyBeforeMaxJump_Hz = f(iBeforeMax);
jumpInfo.FrequencyAfterMaxJump_Hz = f(iAfterMax);
jumpInfo.CpBeforeMaxJump = cp(iBeforeMax);
jumpInfo.CpAfterMaxJump = cp(iAfterMax);

firstLargeLocalIdx = find(relJump > largeJumpThreshold, 1, 'first');
if ~isempty(firstLargeLocalIdx)
    iBefore = idx(firstLargeLocalIdx);
    iAfter = idx(firstLargeLocalIdx+1);
    jumpInfo.FirstLargeJumpRelative = relJump(firstLargeLocalIdx);
    jumpInfo.FrequencyBeforeFirstLargeJump_Hz = f(iBefore);
    jumpInfo.FrequencyAfterFirstLargeJump_Hz = f(iAfter);
    jumpInfo.CpBeforeFirstLargeJump = cp(iBefore);
    jumpInfo.CpAfterFirstLargeJump = cp(iAfter);
    jumpInfo.SafeFmax_Hz = f(iBefore);
end
end

function [frequency, CpPlot] = branchPlotData(branch)
frequency = branch.frequency;
valid = getValidCp(branch);
CpPlot = branch.Cp;
CpPlot(~valid) = nan;
end

function valid = getValidCp(branch)
if isfield(branch, 'validCp')
    valid = branch.validCp;
else
    valid = branch.valid;
end
valid = valid & isfinite(branch.Cp);
end
