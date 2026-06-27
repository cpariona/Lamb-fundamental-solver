% Map the error of the experimental mRLFE A0-like modal atlas solver.
%
% This diagnostic localizes the large errors observed in
% diagnose_mrlfe_a0_modal_atlas and tests whether local minimum refinement
% reduces the discrepancy against the maintained A0-like elastic branch.

clear; clc;
startup

fprintf('\n=== mRLFE A0-like modal atlas error map diagnostic ===\n');

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
geometry = rlComputeGeometry(params);
frequency = rlBuildFrequencyVector(params);

fprintf('Auto frequency points: %d | fmin %.6g Hz | fmax %.6g Hz\n', numel(frequency), min(frequency), max(frequency));

refOptions = rlDefaultOptions("Fast");
refOptions.computeA0 = true;
refOptions.computeS0 = false;
refOptions.computeMRLFE = false;
refOptions.computeMRLFERealK = true;
refOptions.computeMRLFEElasticRealK = true;
refOptions.computeMRLFEViscoRealK = false;
refOptions.computeMRLFEComplexK = false;
refOptions.mrlfeComputeA0Like = true;
refOptions.mrlfeComputeS0Like = false;
refOptions.mrlfeParams = defaultMRLFEParams();
refOptions.mrlfeParams.fluidDensity = 1000;
refOptions.mrlfeParams.fluidSoundSpeed = 1500;
refOptions.mrlfeParams.etaS = 0;
refOptions.mrlfeParams.etaL = 0;
refOptions.mrlfeParams.useComplexLambda = false;

tRef = tic;
rawReference = rlComputeFundamentalLambModes(params, refOptions);
timeReference = toc(tRef);
referenceBranch = rawReference.models.mRLFERealK.branches.A0Like;
referenceCp = referenceBranch.Cp(:);
referenceValid = getBranchValid(referenceBranch);
seedMode = rawReference.modes.A0;

fprintf('Maintained A0Like elastic: %.6g s | valid %d/%d\n', timeReference, nnz(referenceValid), numel(referenceValid));

cases = table();
cases.ScanPoints = [900; 1200; 1600; 1200; 1600];
cases.RefineMinima = [false; false; false; true; true];
cases.Label = ["scan900_no_refine"; "scan1200_no_refine"; "scan1600_no_refine"; "scan1200_refine"; "scan1600_refine"];

summaryRows = table();
pointRows = table();
caseResults = struct();

for i = 1:height(cases)
    scanPoints = cases.ScanPoints(i);
    refine = cases.RefineMinima(i);
    label = string(cases.Label(i));

    atlasOptions = refOptions;
    atlasOptions.mrlfeModalAtlasCpScanPoints = scanPoints;
    atlasOptions.mrlfeModalAtlasTopNMinima = 24;
    atlasOptions.mrlfeModalAtlasMaxLogCpJump = 0.075;
    atlasOptions.mrlfeModalAtlasCpMinFactor = 0.20;
    atlasOptions.mrlfeModalAtlasCpMaxFactor = 2.80;
    atlasOptions.mrlfeModalAtlasCpMaxCeiling = 120;
    atlasOptions.mrlfeModalAtlasMinBranchPoints = 8;
    atlasOptions.mrlfeModalAtlasRequireLowStartRank = false;
    atlasOptions.mrlfeModalAtlasRefineMinima = refine;
    atlasOptions.mrlfeModalAtlasRequireResidualValidity = false;

    tAtlas = tic;
    atlasBranch = solveMRLFEBranchModalAtlas("A0Like", seedMode, material, rmfield(geometry, 'halfThickness'), refOptions.mrlfeParams, atlasOptions);
    timeAtlas = toc(tAtlas);
    atlasCp = atlasBranch.Cp(:);
    atlasValid = getBranchValid(atlasBranch);

    [summary, points] = summarizeCase(label, scanPoints, refine, timeAtlas, frequency, referenceCp, referenceValid, atlasBranch, atlasCp, atlasValid);
    summaryRows = [summaryRows; summary]; %#ok<AGROW>
    pointRows = [pointRows; points]; %#ok<AGROW>

    caseResults(i).label = label; %#ok<SAGROW>
    caseResults(i).atlasBranch = atlasBranch;
    caseResults(i).summary = summary;
    caseResults(i).points = points;

    fprintf('%s: %.6g s | valid %d/%d | RMSE %.6g | P95 %.6g | max %.6g | first large %.6g Hz\n', ...
        label, timeAtlas, summary.ValidAtlas, summary.NumFrequencyPoints, summary.RMSE_mps, ...
        summary.AbsErrorP95_mps, summary.MaxAbsError_mps, summary.FirstAbsErrorAbove050_Hz);
end

fprintf('\nSummary\n');
disp(summaryRows);

fprintf('\nLargest-error points by case\n');
for i = 1:height(cases)
    label = string(cases.Label(i));
    T = pointRows(pointRows.Label == label & isfinite(pointRows.AbsError_mps), :);
    T = sortrows(T, 'AbsError_mps', 'descend');
    fprintf('\n%s\n', label);
    disp(T(1:min(10,height(T)), {'Frequency_Hz','Frequency_kHz','ReferenceCp_mps','AtlasCp_mps','AbsError_mps','RelError','AtlasCandidateRank','AtlasFamilyID'}));
end

assignin('base', 'MRLFEA0ModalAtlasErrorMapSummary', summaryRows);
assignin('base', 'MRLFEA0ModalAtlasErrorMapPoints', pointRows);
assignin('base', 'MRLFEA0ModalAtlasErrorMapCases', caseResults);
assignin('base', 'MRLFEA0ModalAtlasErrorMapReference', rawReference);

fprintf('\nInterpretation guide:\n');
fprintf('  - If refinement lowers RMSE but max error remains high, the issue is modal-family selection.\n');
fprintf('  - If large errors cluster near one frequency band, inspect family switching there.\n');
fprintf('  - If candidate rank/family ID jumps near large errors, improve atlas linking/selection.\n');

function [summary, points] = summarizeCase(label, scanPoints, refine, timeAtlas, frequency, referenceCp, referenceValid, atlasBranch, atlasCp, atlasValid)
frequency = frequency(:);
referenceCp = referenceCp(:);
atlasCp = atlasCp(:);
mask = referenceValid(:) & atlasValid(:) & isfinite(referenceCp) & isfinite(atlasCp);
err = nan(size(frequency));
relErr = nan(size(frequency));
err(mask) = atlasCp(mask) - referenceCp(mask);
relErr(mask) = abs(err(mask)) ./ max(abs(referenceCp(mask)), eps);
absErr = abs(err);

summary = table();
summary.Label = string(label);
summary.ScanPoints = scanPoints;
summary.RefineMinima = logical(refine);
summary.NumFrequencyPoints = numel(frequency);
summary.TimeAtlas_s = timeAtlas;
summary.ValidAtlas = nnz(atlasValid);
summary.OverlapPoints = nnz(mask);
summary.RMSE_mps = sqrt(mean(err(mask).^2, 'omitnan'));
summary.MedianAbsError_mps = median(absErr(mask), 'omitnan');
summary.AbsErrorP90_mps = percentileLocal(absErr(mask), 90);
summary.AbsErrorP95_mps = percentileLocal(absErr(mask), 95);
summary.MaxAbsError_mps = max(absErr(mask), [], 'omitnan');
summary.MedianRelError = median(relErr(mask), 'omitnan');
summary.RelErrorP95 = percentileLocal(relErr(mask), 95);
summary.FirstAbsErrorAbove050_Hz = firstFrequencyAbove(frequency, absErr, 0.50);
summary.FirstAbsErrorAbove100_Hz = firstFrequencyAbove(frequency, absErr, 1.00);
selected = atlasBranch.modalAtlas.selectedFamily;
summary.SelectedBranchID = selected.BranchID;
summary.SelectedCoverage = selected.FrequencyCoverageFraction;
summary.SelectedStartRank = selected.StartRank;
summary.SelectedMedianRank = selected.MedianRank;

points = table();
points.Label = repmat(string(label), numel(frequency), 1);
points.Frequency_Hz = frequency;
points.Frequency_kHz = frequency ./ 1e3;
points.ReferenceCp_mps = referenceCp;
points.ReferenceValid = referenceValid(:);
points.AtlasCp_mps = atlasCp;
points.AtlasValid = atlasValid(:);
points.Error_mps = err;
points.AbsError_mps = absErr;
points.RelError = relErr;
points.AtlasCandidateRank = atlasBranch.candidateRank(:);
points.AtlasFamilyID = atlasBranch.modalAtlasFamilyId(:);
points.AtlasResidual = atlasBranch.residual(:);
end

function valid = getBranchValid(branch)
cp = branch.Cp(:);
valid = isfinite(cp) & cp > 0;
if isfield(branch, 'validCp')
    valid = valid & logical(branch.validCp(:));
elseif isfield(branch, 'valid')
    valid = valid & logical(branch.valid(:));
end
end

function value = percentileLocal(x, p)
x = sort(x(isfinite(x)));
if isempty(x)
    value = nan;
    return;
end
idx = max(1, min(numel(x), ceil((p/100) * numel(x))));
value = x(idx);
end

function value = firstFrequencyAbove(frequency, values, threshold)
idx = find(isfinite(values(:)) & values(:) > threshold, 1, 'first');
if isempty(idx)
    value = nan;
else
    value = frequency(idx);
end
end
