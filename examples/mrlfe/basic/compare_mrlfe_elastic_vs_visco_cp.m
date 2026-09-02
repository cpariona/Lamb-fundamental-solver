% Compare mRLFE elastic real-k and viscoelastic real-k phase velocity.
% This lightweight example is intended for the currently reliable fitting
% exploration range. It compares Cp(f), relative phase-velocity shift, and
% exports compact tables for review.
%
% Model comparison:
%   elastic: lambda real, mu real, k real
%   visco:   lambda real, muStar = mu + 1i*omega*etaS, k real

startup();

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 8000;
params.numFrequencyPoints = 90;
params.frequencySpacing = "hybrid";

etaSValues = [0.1, 0.5, 1.0]; % [Pa*s]
sampleFrequencies = [2000, 4000, 6000, 8000]; % [Hz]
maxAbsShiftForPlot = 0.25; % hide extreme/suspicious relative-shift values in plots

frequency_Hz = rlBuildFrequencyVector(params);

resultsByEtaS = cell(size(etaSValues));
allShiftRows = [];
summaryRows = [];
sampleRows = [];

fprintf('\nmRLFE elastic vs viscoelastic Cp comparison\n');
fprintf('--------------------------------------------\n');
fprintf('Plot shift cutoff: |relative shift| <= %.3g\n', maxAbsShiftForPlot);

for i = 1:numel(etaSValues)
    results = struct('elastic', struct(), 'visco', struct());
    for branchName = ["A0Like", "S0Like"]
        results.elastic.(char(branchName)) = solveCase(params, frequency_Hz, branchName, 0);
        results.visco.(char(branchName)) = solveCase(params, frequency_Hz, branchName, etaSValues(i));
    end
    resultsByEtaS{i} = results;

    fprintf('\netaS = %.4g Pa*s\n', etaSValues(i));
    [shiftRowsA0, summaryA0, samplesA0] = buildShiftTables(results, etaSValues(i), 'A0Like', sampleFrequencies, maxAbsShiftForPlot);
    [shiftRowsS0, summaryS0, samplesS0] = buildShiftTables(results, etaSValues(i), 'S0Like', sampleFrequencies, maxAbsShiftForPlot);
    allShiftRows = [allShiftRows; shiftRowsA0; shiftRowsS0]; %#ok<AGROW>
    summaryRows = [summaryRows; summaryA0; summaryS0]; %#ok<AGROW>
    sampleRows = [sampleRows; samplesA0; samplesS0]; %#ok<AGROW>
end

% Convert/export tables before plotting, so data are available even if figure
% rendering is interrupted.
if isempty(allShiftRows)
    mRLFEElasticViscoCpShiftTable = table();
else
    mRLFEElasticViscoCpShiftTable = struct2table(allShiftRows);
end

if isempty(summaryRows)
    mRLFEElasticViscoCpShiftSummary = table();
else
    mRLFEElasticViscoCpShiftSummary = struct2table(summaryRows);
end

if isempty(sampleRows)
    mRLFEElasticViscoCpShiftSamples = table();
else
    mRLFEElasticViscoCpShiftSamples = struct2table(sampleRows);
end

writetable(mRLFEElasticViscoCpShiftTable, 'mRLFE_elastic_visco_cp_shift_table.csv');
writetable(mRLFEElasticViscoCpShiftSummary, 'mRLFE_elastic_visco_cp_shift_summary.csv');
writetable(mRLFEElasticViscoCpShiftSamples, 'mRLFE_elastic_visco_cp_shift_samples.csv');

% Plot Cp comparison and relative shift for each etaS.
for i = 1:numel(etaSValues)
    results = resultsByEtaS{i};
    figure;
    hold on;
    plotBranchCp(results.elastic.A0Like, 'A0-like elastic', '-');
    plotBranchCp(results.visco.A0Like, 'A0-like visco', '--');
    plotBranchCp(results.elastic.S0Like, 'S0-like elastic', '-');
    plotBranchCp(results.visco.S0Like, 'S0-like visco', '--');
    grid on;
    xlabel('frequency [Hz]');
    ylabel('Phase velocity Cp [m/s]');
    title(sprintf('mRLFE Cp comparison, etaS = %.3g Pa*s', etaSValues(i)));
    legend('Location', 'best');
    hold off;

    figure;
    hold on;
    plotRelativeShift(results, 'A0Like', 'A0-like', maxAbsShiftForPlot);
    plotRelativeShift(results, 'S0Like', 'S0-like', maxAbsShiftForPlot);
    grid on;
    xlabel('frequency [Hz]');
    ylabel('(Cp_{visco} - Cp_{elastic}) / Cp_{elastic} [-]');
    title(sprintf('mRLFE viscoelastic relative Cp shift, etaS = %.3g Pa*s', etaSValues(i)));
    ylim([-maxAbsShiftForPlot, 0.02]);
    legend('Location', 'best');
    hold off;
end

assignin('base', 'mRLFEElasticViscoCpComparisonResults', resultsByEtaS);
assignin('base', 'mRLFEElasticViscoCpComparisonEtaS', etaSValues);
assignin('base', 'mRLFEElasticViscoCpShiftTable', mRLFEElasticViscoCpShiftTable);
assignin('base', 'mRLFEElasticViscoCpShiftSummary', mRLFEElasticViscoCpShiftSummary);
assignin('base', 'mRLFEElasticViscoCpShiftSamples', mRLFEElasticViscoCpShiftSamples);

fprintf('\nExported to workspace:\n');
fprintf('  mRLFEElasticViscoCpComparisonResults\n');
fprintf('  mRLFEElasticViscoCpComparisonEtaS\n');
fprintf('  mRLFEElasticViscoCpShiftTable\n');
fprintf('  mRLFEElasticViscoCpShiftSummary\n');
fprintf('  mRLFEElasticViscoCpShiftSamples\n');
fprintf('Wrote CSV files:\n');
fprintf('  mRLFE_elastic_visco_cp_shift_table.csv\n');
fprintf('  mRLFE_elastic_visco_cp_shift_summary.csv\n');
fprintf('  mRLFE_elastic_visco_cp_shift_samples.csv\n');

function [shiftRows, summaryRow, sampleRows] = buildShiftTables(results, etaS, branchName, sampleFrequencies, maxAbsShiftForPlot)
elastic = results.elastic.(branchName);
visco = results.visco.(branchName);
valid = elastic.validMask(:) & visco.validMask(:);
valid = valid(:);

frequency = elastic.frequency_Hz(:);
CpElastic = elastic.phaseVelocity_mps(:);
CpVisco = visco.phaseVelocity_mps(:);
relativeShift = nan(size(frequency));
relativeShift(valid) = (CpVisco(valid) - CpElastic(valid)) ./ CpElastic(valid);
plotShift = relativeShift;
plotShift(abs(plotShift) > maxAbsShiftForPlot) = nan;

shiftRows = repmat(makeShiftRow(etaS, branchName, nan, nan, nan, nan, false, nan), numel(frequency), 1);
for k = 1:numel(frequency)
    shiftRows(k) = makeShiftRow(etaS, branchName, frequency(k), CpElastic(k), CpVisco(k), relativeShift(k), valid(k), plotShift(k));
end

summaryRow = makeSummaryRow(etaS, branchName, valid, frequency, relativeShift);
printSummary(summaryRow);

sampleRows = repmat(makeSampleRow(etaS, branchName, nan, nan, nan, nan), numel(sampleFrequencies), 1);
for k = 1:numel(sampleFrequencies)
    f = sampleFrequencies(k);
    shiftValid = valid & isfinite(relativeShift(:));
    sampleRows(k) = makeSampleRow(etaS, branchName, f, ...
        interpValid(frequency, CpElastic, valid, f), ...
        interpValid(frequency, CpVisco, valid, f), ...
        interpValid(frequency, relativeShift, shiftValid, f));
end

fprintf('  %s samples:\n', branchName);
for k = 1:numel(sampleRows)
    fprintf('    f = %.0f Hz: Cp_elastic = %.6g, Cp_visco = %.6g, shift = %.4g\n', ...
        sampleRows(k).Frequency_Hz, sampleRows(k).CpElastic, sampleRows(k).CpVisco, sampleRows(k).RelativeShift);
end
end

function value = interpValid(frequency, y, valid, f)
value = nan;
frequency = frequency(:);
y = y(:);
valid = valid(:);
mask = valid & isfinite(frequency) & isfinite(y);
if sum(mask) < 2
    return;
end
if f < min(frequency(mask)) || f > max(frequency(mask))
    return;
end
value = interp1(frequency(mask), y(mask), f, 'linear', nan);
end

function row = makeShiftRow(etaS, branchName, frequency, cpElastic, cpVisco, relativeShift, isValid, plotShift)
row = struct();
row.EtaS_Pa_s = etaS;
row.Branch = string(branchName);
row.Frequency_Hz = frequency;
row.CpElastic = cpElastic;
row.CpVisco = cpVisco;
row.RelativeShift = relativeShift;
row.ValidCommon = logical(isValid);
row.PlotRelativeShift = plotShift;
end

function row = makeSummaryRow(etaS, branchName, valid, frequency, relativeShift)
row = struct();
row.EtaS_Pa_s = etaS;
row.Branch = string(branchName);
row.CommonValidPoints = sum(valid(:));
row.TotalPoints = numel(valid);
row.MinRelativeShift = nan;
row.MaxRelativeShift = nan;
row.MaxAbsShift = nan;
row.FrequencyAtMaxAbsShift_Hz = nan;
row.RelativeShiftAtMaxAbsShift = nan;
mask = valid(:) & isfinite(relativeShift(:));
if any(mask)
    shifts = relativeShift(mask);
    freqs = frequency(mask);
    row.MinRelativeShift = min(shifts);
    row.MaxRelativeShift = max(shifts);
    [row.MaxAbsShift, idx] = max(abs(shifts));
    row.FrequencyAtMaxAbsShift_Hz = freqs(idx);
    row.RelativeShiftAtMaxAbsShift = shifts(idx);
end
end

function row = makeSampleRow(etaS, branchName, frequency, cpElastic, cpVisco, relativeShift)
row = struct();
row.EtaS_Pa_s = etaS;
row.Branch = string(branchName);
row.Frequency_Hz = frequency;
row.CpElastic = cpElastic;
row.CpVisco = cpVisco;
row.RelativeShift = relativeShift;
end

function printSummary(row)
fprintf('  %s common valid: %d / %d, shift %.4g to %.4g, max |shift| %.4g at %.0f Hz\n', ...
    row.Branch, row.CommonValidPoints, row.TotalPoints, row.MinRelativeShift, row.MaxRelativeShift, ...
    row.MaxAbsShift, row.FrequencyAtMaxAbsShift_Hz);
end

function plotBranchCp(branch, labelText, lineStyle)
valid = branch.validMask(:);
y = branch.phaseVelocity_mps;
y(~valid) = nan;
plot(branch.frequency_Hz, y, lineStyle, 'LineWidth', 1.6, 'DisplayName', labelText);
end

function plotRelativeShift(results, branchName, labelText, maxAbsShiftForPlot)
elastic = results.elastic.(branchName);
visco = results.visco.(branchName);
valid = elastic.validMask(:) & visco.validMask(:);
valid = valid(:);
y = nan(size(elastic.phaseVelocity_mps(:)));
cpElastic = elastic.phaseVelocity_mps(:);
cpVisco = visco.phaseVelocity_mps(:);
y(valid) = (cpVisco(valid) - cpElastic(valid)) ./ cpElastic(valid);
y(abs(y) > maxAbsShiftForPlot) = nan;
plot(elastic.frequency_Hz(:), y, 'LineWidth', 1.6, 'DisplayName', labelText);
end

function result = solveCase(params, frequency_Hz, branchName, etaS)
options = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS);
request = mrlfeBuildSolveRequest(params, frequency_Hz, branchName, options);
result = mrlfeSolve(request);
end
