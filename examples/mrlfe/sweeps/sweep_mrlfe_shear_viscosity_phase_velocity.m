% Sweep Han-style solid shear viscosity and plot phase velocity only.
% This example uses mRLFE Han viscoelastic real-k dispersion:
%   lambda real, muStar = mu + 1i*omega*etaS, k real.

startup();

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 8000;
params.numFrequencyPoints = 90;
params.frequencySpacing = "hybrid";

etaSValues = [0, 0.01, 0.05, 0.1, 0.3, 0.5, 0.7, 1.0]; % [Pa*s]

optionsBase = rlDefaultOptions("Fast");
optionsBase.computeA0 = true;
optionsBase.computeS0 = true;
optionsBase.computeMRLFEHanViscoRealK = true;

resultsByEtaS = cell(size(etaSValues));
summaryRows = [];

fprintf('\nmRLFE Han real-k shear viscosity phase-velocity sweep\n');
fprintf('-----------------------------------------------------\n');

for i = 1:numel(etaSValues)
    options = optionsBase;
    mrlfeParams = defaultMRLFEParams();
    mrlfeParams.fluidDensity = 1000;
    mrlfeParams.fluidSoundSpeed = 1500;
    mrlfeParams.etaS = etaSValues(i);
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;
    options.mrlfeParams = mrlfeParams;

    results = rlComputeFundamentalLambModes(params, options);
    resultsByEtaS{i} = results;

    fprintf('etaS = %.4g Pa*s\n', etaSValues(i));
    branches = results.models.mRLFEHanViscoRealK.branches;
    rowA0 = printBranchSummary(branches, 'A0Like', etaSValues(i));
    rowS0 = printBranchSummary(branches, 'S0Like', etaSValues(i));
    summaryRows = [summaryRows; rowA0; rowS0]; %#ok<AGROW>
end

if isempty(summaryRows)
    mRLFEHanViscoSweepSummary = table();
else
    mRLFEHanViscoSweepSummary = struct2table(summaryRows);
end
writetable(mRLFEHanViscoSweepSummary, 'mRLFE_han_visco_sweep_summary.csv');

figure;
hold on;
for i = 1:numel(etaSValues)
    branch = resultsByEtaS{i}.models.mRLFEHanViscoRealK.branches.A0Like;
    [frequency, CpPlot] = branchPlotData(branch);
    plot(frequency, CpPlot, 'LineWidth', 1.5, ...
        'DisplayName', sprintf('etaS = %.3g Pa*s', etaSValues(i)));
end
grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('mRLFE Han real-k A0-like: Cp vs solid shear viscosity');
legend('Location', 'best');
hold off;

figure;
hold on;
for i = 1:numel(etaSValues)
    branch = resultsByEtaS{i}.models.mRLFEHanViscoRealK.branches.S0Like;
    [frequency, CpPlot] = branchPlotData(branch);
    plot(frequency, CpPlot, 'LineWidth', 1.5, ...
        'DisplayName', sprintf('etaS = %.3g Pa*s', etaSValues(i)));
end
grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('mRLFE Han real-k S0-like: Cp vs solid shear viscosity');
legend('Location', 'best');
hold off;

assignin('base', 'mRLFEHanViscoSweepResults', resultsByEtaS);
assignin('base', 'mRLFEHanViscoSweepEtaS', etaSValues);
assignin('base', 'mRLFEHanViscoSweepSummary', mRLFEHanViscoSweepSummary);
fprintf('\nExported mRLFEHanViscoSweepResults, mRLFEHanViscoSweepEtaS, and mRLFEHanViscoSweepSummary to workspace.\n');
fprintf('Wrote mRLFE_han_visco_sweep_summary.csv.\n');

function row = printBranchSummary(branches, branchName, etaS)
row = makeEmptySummaryRow(branchName, etaS);
if ~isfield(branches, branchName)
    fprintf('  %s: not available\n', branchName);
    return;
end
branch = branches.(branchName);
valid = getValidCp(branch);
row.ValidPoints = sum(valid);
row.TotalPoints = numel(branch.Cp);
fprintf('  %s Cp valid: %d / %d\n', branchName, row.ValidPoints, row.TotalPoints);
if any(valid)
    cpValid = branch.Cp(valid);
    fValid = branch.frequency(valid);
    row.MinCp = min(cpValid);
    row.MaxCp = max(cpValid);
    row.ValidFmin_Hz = min(fValid);
    row.ValidFmax_Hz = max(fValid);
    row.FirstValidFrequency_Hz = fValid(1);
    row.LastValidFrequency_Hz = fValid(end);
    fprintf('  %s Cp: %.6g to %.6g m/s\n', branchName, row.MinCp, row.MaxCp);
    fprintf('  %s valid frequency range: %.6g to %.6g Hz; last valid %.6g Hz\n', ...
        branchName, row.ValidFmin_Hz, row.ValidFmax_Hz, row.LastValidFrequency_Hz);
else
    fprintf('  %s valid frequency range: none\n', branchName);
end
if any(isfinite(branch.residual))
    row.MaxResidual = max(branch.residual(isfinite(branch.residual)));
    fprintf('  %s max residual: %.3e\n', branchName, row.MaxResidual);
end
end

function row = makeEmptySummaryRow(branchName, etaS)
row = struct();
row.EtaS_Pa_s = etaS;
row.Branch = string(branchName);
row.ValidPoints = 0;
row.TotalPoints = 0;
row.ValidFmin_Hz = nan;
row.ValidFmax_Hz = nan;
row.FirstValidFrequency_Hz = nan;
row.LastValidFrequency_Hz = nan;
row.MinCp = nan;
row.MaxCp = nan;
row.MaxResidual = nan;
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
