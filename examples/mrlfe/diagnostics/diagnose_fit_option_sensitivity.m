% Diagnose mRLFE speed/accuracy sensitivity to fitting solver options.
% Diagnostic only: does not change solver internals.
%
% This script compares lower-cost A0Like DP/tracking settings against a high-cost
% reference forward solution. It explicitly disables the automatic fitting
% performance preset so the tested options are not overwritten.

clear; clc;
startup

branchName = "A0Like";
etaS = 0.0;
trueMu = 75e3;
frequency_Hz = linspace(1000, 8000, 10).';

params = mrlfeDefaultSweepParams();
params.mu = trueMu;
params.thickness = 0.50e-3;
params.rho = 1070;
params.nu = 0.4999;
params.etaS = etaS;

referenceOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS);
referenceOptions.mrlfeUseFitPerformanceDefaults = false;
referenceOptions.mrlfeUseInternalTrackingGrid = true;
referenceOptions.mrlfeInternalTrackingMinPoints = 30;
referenceOptions.mrlfeInternalTrackingPointFactor = 2;
referenceOptions.mrlfeInternalTrackingMaxPoints = 80;
referenceOptions.mrlfeA0DPCpScanPoints = 2200;
referenceOptions.mrlfeA0DPCandidates = 8;

fprintf('\n=== mRLFE fitting option sensitivity diagnostic ===\n');
fprintf('Branch: %s | etaS = %.4g Pa*s | mu = %.3f kPa\n', branchName, etaS, trueMu/1e3);
fprintf('Frequencies: %.0f to %.0f Hz | requested points = %d\n', min(frequency_Hz), max(frequency_Hz), numel(frequency_Hz));

fprintf('\nReference forward solution...\n');
tRef = tic;
[CpRef, rawRef] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, referenceOptions);
timeRef = toc(tRef);
validRef = isfinite(CpRef(:));
assert(any(validRef), 'Reference mRLFE forward solution produced no valid points.');

fprintf('  time = %.6g s\n', timeRef);
fprintf('  tracking points = %d\n', getTrackingPointCount(rawRef));
fprintf('  solver elapsed = %.6g s\n', getSolverElapsedSeconds(rawRef));
fprintf('  Cp reference = [%s ]\n', sprintf(' %.6f', CpRef(:)));

cpScanPointsList = [300; 500; 800; 1200; 1600; 2200];
trackingMinPointsList = [10; 20; 30];
pointFactorList = [1; 2];

rows = [];
rowIndex = 0;
for i = 1:numel(cpScanPointsList)
    for j = 1:numel(trackingMinPointsList)
        for k = 1:numel(pointFactorList)
            options = referenceOptions;
            options.mrlfeA0DPCpScanPoints = cpScanPointsList(i);
            options.mrlfeInternalTrackingMinPoints = trackingMinPointsList(j);
            options.mrlfeInternalTrackingPointFactor = pointFactorList(k);

            tEval = tic;
            [CpTest, rawTest] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, options);
            elapsed = toc(tEval);

            valid = validRef(:) & isfinite(CpTest(:));
            validFraction = nnz(valid) / max(1, nnz(validRef));
            diff = CpTest(valid) - CpRef(valid);
            if isempty(diff)
                rmseDiff = NaN;
                maxAbsDiff = NaN;
                maxRelDiff = NaN;
            else
                rmseDiff = sqrt(mean(diff.^2, 'omitnan'));
                maxAbsDiff = max(abs(diff));
                maxRelDiff = max(abs(diff) ./ max(abs(CpRef(valid)), eps));
            end

            rowIndex = rowIndex + 1;
            rows(rowIndex).cpScanPoints = cpScanPointsList(i); %#ok<SAGROW>
            rows(rowIndex).trackingMinPoints = trackingMinPointsList(j); %#ok<SAGROW>
            rows(rowIndex).pointFactor = pointFactorList(k); %#ok<SAGROW>
            rows(rowIndex).forwardSeconds = elapsed; %#ok<SAGROW>
            rows(rowIndex).solverSeconds = getSolverElapsedSeconds(rawTest); %#ok<SAGROW>
            rows(rowIndex).trackingPoints = getTrackingPointCount(rawTest); %#ok<SAGROW>
            rows(rowIndex).validFraction = validFraction; %#ok<SAGROW>
            rows(rowIndex).rmseDiff_mps = rmseDiff; %#ok<SAGROW>
            rows(rowIndex).maxAbsDiff_mps = maxAbsDiff; %#ok<SAGROW>
            rows(rowIndex).maxRelDiff = maxRelDiff; %#ok<SAGROW>
            rows(rowIndex).speedupVsReference = timeRef / elapsed; %#ok<SAGROW>
        end
    end
end

T = struct2table(rows);
T = sortrows(T, {'validFraction','rmseDiff_mps','forwardSeconds'}, {'descend','ascend','ascend'});

fprintf('\nOption sensitivity table sorted by valid fraction, Cp error, and time:\n');
disp(T);

usable = T.validFraction >= 1.0 & T.rmseDiff_mps < 0.05;
if any(usable)
    Tu = sortrows(T(usable,:), 'forwardSeconds', 'ascend');
    fprintf('\nFastest usable settings with RMSE difference < 0.05 m/s against reference:\n');
    disp(Tu(1:min(8,height(Tu)), :));
else
    fprintf('\nNo tested setting reached validFraction = 1 and RMSE difference < 0.05 m/s.\n');
end

summary = struct();
summary.referenceOptions = referenceOptions;
summary.referenceCp = CpRef;
summary.referenceRaw = rawRef;
summary.referenceSeconds = timeRef;
summary.resultsTable = T;
summary.usableTable = T(usable,:);
assignin('base', 'MRLFEFitOptionSensitivityDiagnostic', summary);

fprintf('\nInterpretation notes:\n');
fprintf('  - If low cpScanPoints keep Cp error small, a faster fitting preset is justified before an atlas rewrite.\n');
fprintf('  - If trackingMinPoints dominates time weakly but cpScanPoints dominates strongly, optimize DP candidate extraction first.\n');
fprintf('  - If all lower scan settings alter Cp materially, a multi-resolution/local-refinement atlas is safer than simply lowering scan density.\n');

function n = getTrackingPointCount(rawResult)
n = NaN;
try
    if isfield(rawResult, 'rawFullResult') && isfield(rawResult.rawFullResult, 'models') && ...
            isfield(rawResult.rawFullResult.models, 'mRLFERealK') && ...
            isfield(rawResult.rawFullResult.models.mRLFERealK, 'diagnostics')
        n = rawResult.rawFullResult.models.mRLFERealK.diagnostics.trackingPointCount;
    elseif isfield(rawResult, 'branchSolve') && isfield(rawResult.branchSolve, 'frequency')
        n = numel(rawResult.branchSolve.frequency);
    end
catch
    n = NaN;
end
end

function t = getSolverElapsedSeconds(rawResult)
t = NaN;
try
    if isfield(rawResult, 'rawFullResult') && isfield(rawResult.rawFullResult, 'models') && ...
            isfield(rawResult.rawFullResult.models, 'mRLFERealK') && ...
            isfield(rawResult.rawFullResult.models.mRLFERealK, 'diagnostics')
        t = rawResult.rawFullResult.models.mRLFERealK.diagnostics.elapsedSeconds;
    end
catch
    t = NaN;
end
end
