% Diagnose experimental modal-atlas mRLFE A0-like solver.
%
% Compares the maintained mRLFE A0-like elastic branch against the experimental
% modal-atlas branch for the GUI-style 32 kHz case.

clear; clc;
startup

fprintf('\n=== mRLFE A0-like modal atlas diagnostic ===\n');

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
omega = 2*pi*frequency(:);

fprintf('Auto frequency points: %d | fmin %.6g Hz | fmax %.6g Hz\n', numel(frequency), min(frequency), max(frequency));

% Maintained reference.
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

scanPointsList = [350, 500, 700, 900, 1200];
summaryRows = table();
caseResults = struct();

for i = 1:numel(scanPointsList)
    scanPoints = scanPointsList(i);
    atlasOptions = refOptions;
    atlasOptions.mrlfeModalAtlasCpScanPoints = scanPoints;
    atlasOptions.mrlfeModalAtlasTopNMinima = 18;
    atlasOptions.mrlfeModalAtlasMaxLogCpJump = 0.075;
    atlasOptions.mrlfeModalAtlasCpMinFactor = 0.20;
    atlasOptions.mrlfeModalAtlasCpMaxFactor = 2.80;
    atlasOptions.mrlfeModalAtlasCpMaxCeiling = 120;
    atlasOptions.mrlfeModalAtlasMinBranchPoints = 8;
    atlasOptions.mrlfeModalAtlasRequireLowStartRank = false;
    atlasOptions.mrlfeModalAtlasRefineMinima = false;
    atlasOptions.mrlfeModalAtlasRequireResidualValidity = false;

    mrlfeParams = refOptions.mrlfeParams;
    tAtlas = tic;
    atlasBranch = solveMRLFEBranchModalAtlas("A0Like", seedMode, material, rmfield(geometry, 'halfThickness'), mrlfeParams, atlasOptions);
    timeAtlas = toc(tAtlas);
    atlasCp = atlasBranch.Cp(:);
    atlasValid = getBranchValid(atlasBranch);

    mask = referenceValid(:) & atlasValid(:) & isfinite(referenceCp(:)) & isfinite(atlasCp(:));
    rmse = nan;
    maxAbs = nan;
    if any(mask)
        diff = atlasCp(mask) - referenceCp(mask);
        rmse = sqrt(mean(diff.^2, 'omitnan'));
        maxAbs = max(abs(diff), [], 'omitnan');
    end

    selected = atlasBranch.modalAtlas.selectedFamily;
    if isempty(selected)
        selectedBranchID = nan;
        coverage = nan;
        startRank = nan;
        medianRank = nan;
        roughness = nan;
    else
        selectedBranchID = selected.BranchID;
        coverage = selected.FrequencyCoverageFraction;
        startRank = selected.StartRank;
        medianRank = selected.MedianRank;
        roughness = selected.Roughness;
    end

    row = table();
    row.ScanPoints = scanPoints;
    row.TimeAtlas_s = timeAtlas;
    row.TimeReference_s = timeReference;
    row.ValidAtlas = nnz(atlasValid);
    row.ValidReference = nnz(referenceValid);
    row.OverlapPoints = nnz(mask);
    row.RMSE_vs_Reference_mps = rmse;
    row.MaxAbs_vs_Reference_mps = maxAbs;
    row.SelectedBranchID = selectedBranchID;
    row.SelectedCoverage = coverage;
    row.SelectedStartRank = startRank;
    row.SelectedMedianRank = medianRank;
    row.SelectedRoughness = roughness;
    summaryRows = [summaryRows; row]; %#ok<AGROW>

    caseResults(i).scanPoints = scanPoints; %#ok<SAGROW>
    caseResults(i).atlasBranch = atlasBranch;
    caseResults(i).atlasCp = atlasCp;
    caseResults(i).atlasValid = atlasValid;
    caseResults(i).mask = mask;

    fprintf('Atlas scan %d: %.6g s | valid %d/%d | overlap %d | RMSE %.6g | max abs %.6g\n', ...
        scanPoints, timeAtlas, nnz(atlasValid), numel(atlasValid), nnz(mask), rmse, maxAbs);
end

fprintf('\nSummary\n');
disp(summaryRows);

assignin('base', 'MRLFEA0ModalAtlasSummary', summaryRows);
assignin('base', 'MRLFEA0ModalAtlasCases', caseResults);
assignin('base', 'MRLFEA0ModalAtlasReference', rawReference);

fprintf('\nInterpretation guide:\n');
fprintf('  - This is an experimental modal-atlas solver, not the maintained production path.\n');
fprintf('  - Favor cases with much lower time, high overlap, and small RMSE vs maintained branch.\n');
fprintf('  - If overlap is high but RMSE is large, the atlas is selecting a different modal family.\n');
fprintf('  - If valid points improve but RMSE is acceptable, the modal-atlas policy may be better than the current DP tracker.\n');

function valid = getBranchValid(branch)
cp = branch.Cp(:);
valid = isfinite(cp) & cp > 0;
if isfield(branch, 'validCp')
    valid = valid & logical(branch.validCp(:));
elseif isfield(branch, 'valid')
    valid = valid & logical(branch.valid(:));
end
end
