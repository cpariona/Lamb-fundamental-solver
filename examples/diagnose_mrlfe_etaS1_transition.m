% Diagnose the etaS = 1 Pa*s transition near 6-9 kHz.
%
% Motivation:
%   The Han real-k curves show a strong Cp decrease near the upper end of the
%   8 kHz range. This script uses a very fine linear frequency grid to check
%   whether the drop is abrupt or smooth, and compares real-k Han dispersion
%   with the experimental complex-k path to estimate spatial loss factor.
%
% Models inspected:
%   1) mRLFE elastic real-k
%   2) mRLFE Han viscoelastic real-k, muStar = mu + i*omega*etaS
%   3) mRLFE complex-k experimental, reporting kImag/kReal
%
% Important:
%   complex-k attenuation is still experimental and not validated for fitting.

startup();

params = defaultParams();
params.fmin = 6000;
params.fmax = 9000;
params.numFrequencyPoints = 401;     % fine spacing: about 7.5 Hz
params.frequencySpacing = "linspace";

etaS = 1.0; % [Pa*s]

options = defaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = true;
options.computeMRLFERealK = true;
options.computeMRLFEHanViscoRealK = true;
options.computeMRLFEComplexK = true;

mrlfeParams = defaultMRLFEParams();
mrlfeParams.fluidDensity = 1000;
mrlfeParams.fluidSoundSpeed = 1500;
mrlfeParams.etaS = etaS;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
options.mrlfeParams = mrlfeParams;

fprintf('\nmRLFE etaS = %.3g Pa*s transition diagnostic\n', etaS);
fprintf('------------------------------------------------\n');
fprintf('Frequency range %.0f to %.0f Hz, N = %d\n', params.fmin, params.fmax, params.numFrequencyPoints);

results = computeFundamentalLambModes(params, options);

transitionTable = buildTransitionTable(results, etaS);
summaryTable = summarizeTransitionTable(transitionTable);

writetable(transitionTable, 'mRLFE_etaS1_transition_table.csv');
writetable(summaryTable, 'mRLFE_etaS1_transition_summary.csv');
assignin('base', 'mRLFE_EtaS1TransitionResults', results);
assignin('base', 'mRLFE_EtaS1TransitionTable', transitionTable);
assignin('base', 'mRLFE_EtaS1TransitionSummary', summaryTable);

fprintf('\nTransition summary\n');
fprintf('------------------\n');
disp(summaryTable);
fprintf('\nWrote mRLFE_etaS1_transition_table.csv and mRLFE_etaS1_transition_summary.csv\n');

% Plot phase velocity: elastic real-k, Han real-k, and complex-k Cp.
figure;
hold on;
plotBranch(results.models.mRLFEElasticRealK.branches.A0Like, 'A0-like elastic real-k', '-');
plotBranch(results.models.mRLFEHanViscoRealK.branches.A0Like, 'A0-like Han real-k', '--');
plotBranch(results.models.mRLFEComplexK.branches.A0Like, 'A0-like complex-k Cp', '-.');
plotBranch(results.models.mRLFEElasticRealK.branches.S0Like, 'S0-like elastic real-k', '-');
plotBranch(results.models.mRLFEHanViscoRealK.branches.S0Like, 'S0-like Han real-k', '--');
plotBranch(results.models.mRLFEComplexK.branches.S0Like, 'S0-like complex-k Cp', '-.');
grid on;
xlabel('frequency [Hz]');
ylabel('Phase velocity Cp [m/s]');
title('mRLFE etaS = 1 Pa*s transition: Cp comparison');
legend('Location', 'best');
hold off;

% Plot relative shift from elastic and complex-k loss factor.
figure;
hold on;
plotMetric(transitionTable, 'A0Like', 'RelativeShiftHanVsElastic', 'A0 Han vs elastic');
plotMetric(transitionTable, 'S0Like', 'RelativeShiftHanVsElastic', 'S0 Han vs elastic');
grid on;
xlabel('frequency [Hz]');
ylabel('(Cp_{Han real-k} - Cp_{elastic}) / Cp_{elastic} [-]');
title('Relative Cp shift, etaS = 1 Pa*s');
legend('Location', 'best');
hold off;

figure;
hold on;
plotMetric(transitionTable, 'A0Like', 'ComplexLossFactor', 'A0 complex-k k_i/k_r');
plotMetric(transitionTable, 'S0Like', 'ComplexLossFactor', 'S0 complex-k k_i/k_r');
grid on;
xlabel('frequency [Hz]');
ylabel('k_i / k_r [-]');
title('Experimental complex-k spatial loss factor, etaS = 1 Pa*s');
legend('Location', 'best');
hold off;

% Real-k residual map around the transition, overlaid with tracked Cp curves.
plotResidualMap(results, params, mrlfeParams, 'A0Like');
plotResidualMap(results, params, mrlfeParams, 'S0Like');

function tableOut = buildTransitionTable(results, etaS)
branches = ["A0Like", "S0Like"];
rows = [];
for i = 1:numel(branches)
    branchName = branches(i);
    elastic = results.models.mRLFEElasticRealK.branches.(branchName);
    han = results.models.mRLFEHanViscoRealK.branches.(branchName);
    complexK = results.models.mRLFEComplexK.branches.(branchName);
    f = elastic.frequency(:);
    validElastic = getValidCp(elastic);
    validHan = getValidCp(han);
    validComplex = getValidCp(complexK);
    for j = 1:numel(f)
        cpElastic = getValue(elastic.Cp, j);
        cpHan = getValue(han.Cp, j);
        cpComplex = getValue(complexK.Cp, j);
        kRealComplex = getValue(complexK.kReal, j);
        kImagComplex = getValue(complexK.kImag, j);
        lossFactor = nan;
        if isfinite(kRealComplex) && kRealComplex > 0 && isfinite(kImagComplex)
            lossFactor = kImagComplex / kRealComplex;
        end
        relShift = nan;
        if validElastic(j) && validHan(j) && isfinite(cpElastic) && cpElastic > 0 && isfinite(cpHan)
            relShift = (cpHan - cpElastic) / cpElastic;
        end
        rows = [rows; makeRow(etaS, branchName, f(j), cpElastic, cpHan, cpComplex, ...
            relShift, kRealComplex, kImagComplex, lossFactor, validElastic(j), validHan(j), validComplex(j), ...
            getValue(han.residual, j), getValue(complexK.residual, j))]; %#ok<AGROW>
    end
end
if isempty(rows)
    tableOut = table();
else
    tableOut = struct2table(rows);
end
end

function summary = summarizeTransitionTable(T)
branches = unique(T.Branch, 'stable');
rows = [];
for i = 1:numel(branches)
    branchName = branches(i);
    mask = T.Branch == branchName;
    validShift = mask & T.ValidElastic & T.ValidHan & isfinite(T.RelativeShiftHanVsElastic);
    validLoss = mask & T.ValidComplexK & isfinite(T.ComplexLossFactor);
    row = struct();
    row.Branch = branchName;
    row.CommonValidRealKPoints = sum(validShift);
    row.ValidComplexKPoints = sum(validLoss);
    row.MinRelativeShift = nan;
    row.MaxRelativeShift = nan;
    row.MaxAbsRelativeShift = nan;
    row.FrequencyAtMaxAbsShift_Hz = nan;
    row.MaxComplexLossFactor = nan;
    row.FrequencyAtMaxLossFactor_Hz = nan;
    if any(validShift)
        shifts = T.RelativeShiftHanVsElastic(validShift);
        freqs = T.Frequency_Hz(validShift);
        row.MinRelativeShift = min(shifts);
        row.MaxRelativeShift = max(shifts);
        [row.MaxAbsRelativeShift, idx] = max(abs(shifts));
        row.FrequencyAtMaxAbsShift_Hz = freqs(idx);
    end
    if any(validLoss)
        loss = T.ComplexLossFactor(validLoss);
        freqs = T.Frequency_Hz(validLoss);
        [row.MaxComplexLossFactor, idx] = max(loss);
        row.FrequencyAtMaxLossFactor_Hz = freqs(idx);
    end
    rows = [rows; row]; %#ok<AGROW>
end
summary = struct2table(rows);
end

function row = makeRow(etaS, branchName, frequency, cpElastic, cpHan, cpComplex, relShift, kRealComplex, kImagComplex, lossFactor, validElastic, validHan, validComplex, residualHan, residualComplex)
row = struct();
row.EtaS_Pa_s = etaS;
row.Branch = string(branchName);
row.Frequency_Hz = frequency;
row.CpElasticRealK = cpElastic;
row.CpHanRealK = cpHan;
row.CpComplexK = cpComplex;
row.RelativeShiftHanVsElastic = relShift;
row.ComplexKReal = kRealComplex;
row.ComplexKImag = kImagComplex;
row.ComplexLossFactor = lossFactor;
row.ValidElastic = logical(validElastic);
row.ValidHan = logical(validHan);
row.ValidComplexK = logical(validComplex);
row.ResidualHan = residualHan;
row.ResidualComplexK = residualComplex;
end

function value = getValue(x, idx)
x = x(:);
if idx <= numel(x)
    value = x(idx);
else
    value = nan;
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

function plotBranch(branch, labelText, lineStyle)
valid = getValidCp(branch);
y = branch.Cp(:);
y(~valid) = nan;
plot(branch.frequency(:), y, lineStyle, 'LineWidth', 1.5, 'DisplayName', labelText);
end

function plotMetric(T, branchName, variableName, labelText)
mask = T.Branch == string(branchName);
x = T.Frequency_Hz(mask);
y = T.(variableName)(mask);
plot(x, y, 'LineWidth', 1.5, 'DisplayName', labelText);
end

function plotResidualMap(results, params, mrlfeParams, branchName)
fMap = linspace(params.fmin, params.fmax, 180);
CpMap = linspace(4, 26, 700);
material = results.material;
geometry = results.geometry;
Rmap = nan(numel(CpMap), numel(fMap));
for j = 1:numel(fMap)
    omega = 2*pi*fMap(j);
    for i = 1:numel(CpMap)
        k = omega / CpMap(i);
        Rmap(i,j) = mrlfeResidual(k, omega, material, geometry, mrlfeParams);
    end
end
figure;
imagesc(fMap, CpMap, log10(Rmap));
set(gca, 'YDir', 'normal');
colorbar;
xlabel('frequency [Hz]');
ylabel('Trial Cp [m/s]');
title(sprintf('Real-k residual map near etaS = 1 transition: %s', branchName));
hold on;
if isfield(results.models.mRLFEElasticRealK.branches, branchName)
    b = results.models.mRLFEElasticRealK.branches.(branchName);
    plot(b.frequency, b.Cp, 'w-', 'LineWidth', 1.2, 'DisplayName', 'elastic real-k');
end
if isfield(results.models.mRLFEHanViscoRealK.branches, branchName)
    b = results.models.mRLFEHanViscoRealK.branches.(branchName);
    valid = getValidCp(b);
    y = b.Cp(:);
    y(~valid) = nan;
    plot(b.frequency(:), y, 'k-', 'LineWidth', 1.2, 'DisplayName', 'Han real-k');
end
hold off;
end
