% Diagnose cost/accuracy tradeoff for mRLFE A0-like DP scan points.
%
% The 32 kHz GUI diagnostic shows that A0-like elastic real-k dominates the
% runtime. This script compares different mrlfeA0DPCpScanPoints values against
% the current maintained reference value.

clear; clc;
startup

fprintf('\n=== mRLFE A0-like DP scan cost diagnostic ===\n');

params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 158e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 10;
params.fmax = 32e3;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";

material = rlComputeMaterial(params);
params.E = material.E;
params.K = material.K;
params.CL = material.CL;
params.CT = material.CT;
params.lambda = material.lambda;
params.nu = material.nu;

frequency = rlBuildFrequencyVector(params);
fprintf('Auto frequency points: %d | fmin %.6g Hz | fmax %.6g Hz\n', numel(frequency), min(frequency), max(frequency));

robustness = "Fast";
scanPointsList = [350, 500, 700, 900, 1200, 1600, 2200];
referenceScanPoints = 2200;
summaryRows = table();
caseResults = struct();
referenceCp = [];
referenceValid = [];

for i = 1:numel(scanPointsList)
    scanPoints = scanPointsList(i);
    options = makeOptions(robustness, scanPoints);
    label = sprintf('A0Like elastic | scan %d', scanPoints);
    fprintf('\nCase: %s\n', label);

    t = tic;
    raw = rlComputeFundamentalLambModes(params, options);
    elapsed = toc(t);

    [cp, valid] = getA0LikeBranch(raw);
    if scanPoints == referenceScanPoints
        referenceCp = cp;
        referenceValid = valid;
    end

    caseResults(i).label = label; %#ok<SAGROW>
    caseResults(i).scanPoints = scanPoints;
    caseResults(i).elapsed = elapsed;
    caseResults(i).raw = raw;
    caseResults(i).cp = cp;
    caseResults(i).valid = valid;

    row = table();
    row.ScanPoints = scanPoints;
    row.Elapsed_s = elapsed;
    row.ValidPoints = nnz(valid);
    row.ValidFraction = nnz(valid) / numel(frequency);
    row.FirstInvalidFrequency_Hz = firstInvalidFrequency(frequency, valid);
    row.RMSE_vs_Reference_mps = nan;
    row.MaxAbs_vs_Reference_mps = nan;
    summaryRows = [summaryRows; row]; %#ok<AGROW>

    fprintf('  elapsed %.6g s | valid %d/%d\n', elapsed, nnz(valid), numel(valid));
end

if isempty(referenceCp)
    error('Reference scan point case was not computed.');
end

for i = 1:numel(caseResults)
    cp = caseResults(i).cp;
    valid = caseResults(i).valid;
    mask = valid(:) & referenceValid(:) & isfinite(cp(:)) & isfinite(referenceCp(:));
    if any(mask)
        diff = cp(mask) - referenceCp(mask);
        summaryRows.RMSE_vs_Reference_mps(i) = sqrt(mean(diff.^2, 'omitnan'));
        summaryRows.MaxAbs_vs_Reference_mps(i) = max(abs(diff), [], 'omitnan');
    end
end

fprintf('\nSummary\n');
disp(summaryRows);

assignin('base', 'MRLFEA0DPScanCostSummary', summaryRows);
assignin('base', 'MRLFEA0DPScanCostCases', caseResults);
assignin('base', 'MRLFEA0DPScanCostFrequency', frequency);

fprintf('\nInterpretation guide:\n');
fprintf('  - Look for the smallest ScanPoints value with the same ValidPoints and small RMSE.\n');
fprintf('  - If 700-900 scan points match 2200, the GUI Fast policy can be reduced safely.\n');
fprintf('  - If all reduced scans fail, the bottleneck requires algorithmic changes, not only options.\n');

function options = makeOptions(robustness, scanPoints)
options = rlDefaultOptions(robustness);
options.computeA0 = true;
options.computeS0 = false;
options.computeMRLFE = false;
options.computeMRLFERealK = true;
options.computeMRLFEElasticRealK = true;
options.computeMRLFEViscoRealK = false;
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;
options.mrlfeParams.etaS = 0;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;
options.mrlfeA0DPCpScanPoints = scanPoints;
end

function [cp, valid] = getA0LikeBranch(raw)
branch = raw.models.mRLFERealK.branches.A0Like;
cp = branch.Cp(:);
if isfield(branch, 'validCp')
    valid = logical(branch.validCp(:)) & isfinite(cp);
elseif isfield(branch, 'valid')
    valid = logical(branch.valid(:)) & isfinite(cp);
else
    valid = isfinite(cp);
end
end

function value = firstInvalidFrequency(frequency, valid)
idx = find(~valid(:), 1, 'first');
if isempty(idx)
    value = nan;
else
    value = frequency(idx);
end
end
