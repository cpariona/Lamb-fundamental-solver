% Sweep Han-style solid shear viscosity and plot phase velocity only.
% This example uses mRLFE Han viscoelastic real-k dispersion:
%   lambda real, muStar = mu + 1i*omega*etaS, k real.

startup();

params = defaultParams();
params.fmin = 500;
params.fmax = 8000;
params.numFrequencyPoints = 90;
params.frequencySpacing = "hybrid";

etaSValues = [0, 0.01, 0.05, 0.1, 0.3, 0.5, 0.7, 1.0]; % [Pa*s]

optionsBase = defaultOptions("Fast");
optionsBase.computeA0 = true;
optionsBase.computeS0 = true;
optionsBase.computeMRLFEHanViscoRealK = true;

resultsByEtaS = cell(size(etaSValues));

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

    results = computeFundamentalLambModes(params, options);
    resultsByEtaS{i} = results;

    fprintf('etaS = %.4g Pa*s\n', etaSValues(i));
    branches = results.models.mRLFEHanViscoRealK.branches;
    printBranchSummary(branches, 'A0Like');
    printBranchSummary(branches, 'S0Like');
end

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
fprintf('\nExported mRLFEHanViscoSweepResults and mRLFEHanViscoSweepEtaS to workspace.\n');

function printBranchSummary(branches, branchName)
if ~isfield(branches, branchName)
    fprintf('  %s: not available\n', branchName);
    return;
end
branch = branches.(branchName);
valid = getValidCp(branch);
fprintf('  %s Cp valid: %d / %d\n', branchName, sum(valid), numel(branch.Cp));
if any(valid)
    fprintf('  %s Cp: %.6g to %.6g m/s\n', branchName, min(branch.Cp(valid)), max(branch.Cp(valid)));
end
if any(isfinite(branch.residual))
    fprintf('  %s max residual: %.3e\n', branchName, max(branch.residual(isfinite(branch.residual))));
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
