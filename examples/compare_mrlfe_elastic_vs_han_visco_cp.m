% Compare mRLFE elastic real-k and Han viscoelastic real-k phase velocity.
% This lightweight example is intended for the currently reliable fitting
% exploration range. It compares Cp(f) and the relative phase-velocity shift
% caused by Kelvin-Voigt shear viscosity.
%
% Model comparison:
%   elastic: lambda real, mu real, k real
%   Han visco: lambda real, muStar = mu + 1i*omega*etaS, k real

startup();

params = defaultParams();
params.fmin = 500;
params.fmax = 8000;
params.numFrequencyPoints = 90;
params.frequencySpacing = "hybrid";

etaSValues = [0.1, 0.5, 1.0]; % [Pa*s]

optionsBase = defaultOptions("Fast");
optionsBase.computeA0 = true;
optionsBase.computeS0 = true;
optionsBase.computeMRLFERealK = true;
optionsBase.computeMRLFEHanViscoRealK = true;

resultsByEtaS = cell(size(etaSValues));

fprintf('\nmRLFE elastic vs Han viscoelastic Cp comparison\n');
fprintf('------------------------------------------------\n');

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
    printShiftSummary(results, 'A0Like');
    printShiftSummary(results, 'S0Like');
end

% Plot Cp comparison for each etaS.
for i = 1:numel(etaSValues)
    results = resultsByEtaS{i};
    figure;
    hold on;
    plotBranchCp(results.models.mRLFEElasticRealK.branches.A0Like, 'A0-like elastic', '-');
    plotBranchCp(results.models.mRLFEHanViscoRealK.branches.A0Like, 'A0-like Han visco', '--');
    plotBranchCp(results.models.mRLFEElasticRealK.branches.S0Like, 'S0-like elastic', '-');
    plotBranchCp(results.models.mRLFEHanViscoRealK.branches.S0Like, 'S0-like Han visco', '--');
    grid on;
    xlabel('frequency [Hz]');
    ylabel('Phase velocity Cp [m/s]');
    title(sprintf('mRLFE Cp comparison, etaS = %.3g Pa*s', etaSValues(i)));
    legend('Location', 'best');
    hold off;

    figure;
    hold on;
    plotRelativeShift(results, 'A0Like', 'A0-like');
    plotRelativeShift(results, 'S0Like', 'S0-like');
    grid on;
    xlabel('frequency [Hz]');
    ylabel('(Cp_{visco} - Cp_{elastic}) / Cp_{elastic} [-]');
    title(sprintf('mRLFE Han viscoelastic relative Cp shift, etaS = %.3g Pa*s', etaSValues(i)));
    legend('Location', 'best');
    hold off;
end

assignin('base', 'mRLFEElasticHanCpComparisonResults', resultsByEtaS);
assignin('base', 'mRLFEElasticHanCpComparisonEtaS', etaSValues);
fprintf('\nExported mRLFEElasticHanCpComparisonResults and mRLFEElasticHanCpComparisonEtaS to workspace.\n');

function printShiftSummary(results, branchName)
elastic = results.models.mRLFEElasticRealK.branches.(branchName);
visco = results.models.mRLFEHanViscoRealK.branches.(branchName);
valid = getValidCp(elastic) & getValidCp(visco);
if ~any(valid)
    fprintf('  %s: no common valid points\n', branchName);
    return;
end
shift = (visco.Cp(valid) - elastic.Cp(valid)) ./ elastic.Cp(valid);
fprintf('  %s common valid: %d / %d, relative Cp shift: %.3g to %.3g\n', ...
    branchName, sum(valid), numel(valid), min(shift), max(shift));
end

function plotBranchCp(branch, labelText, lineStyle)
valid = getValidCp(branch);
y = branch.Cp;
y(~valid) = nan;
plot(branch.frequency, y, lineStyle, 'LineWidth', 1.6, 'DisplayName', labelText);
end

function plotRelativeShift(results, branchName, labelText)
elastic = results.models.mRLFEElasticRealK.branches.(branchName);
visco = results.models.mRLFEHanViscoRealK.branches.(branchName);
valid = getValidCp(elastic) & getValidCp(visco);
y = nan(size(elastic.Cp));
y(valid) = (visco.Cp(valid) - elastic.Cp(valid)) ./ elastic.Cp(valid);
plot(elastic.frequency, y, 'LineWidth', 1.6, 'DisplayName', labelText);
end

function valid = getValidCp(branch)
if isfield(branch, 'validCp')
    valid = branch.validCp;
else
    valid = branch.valid;
end
valid = valid & isfinite(branch.Cp);
end
