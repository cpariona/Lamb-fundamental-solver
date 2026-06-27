% Diagnose whether the direct mRLFE Cp-atlas route is valid at etaS = 0.
% Diagnostic only: this does not replace the maintained solver.
%
% This compares the maintained elastic real-k mRLFE branch against the direct
% residual-atlas branch evaluated with etaS = 0. If agreement is strong, the
% direct atlas may become a candidate for a unified mRLFE interface path.

clear; clc;
startup

branches = ["A0Like", "S0Like"];
frequency_Hz = linspace(1000, 8000, 10).';

params = mrlfeDefaultSweepParams();
params.mu = 75e3;
params.thickness = 0.50e-3;
params.rho = 1070;
params.nu = 0.4999;
params.etaS = 0;

fprintf('\n=== mRLFE direct atlas etaS = 0 diagnostic ===\n');
fprintf('Frequencies: %.0f to %.0f Hz | requested points = %d\n', min(frequency_Hz), max(frequency_Hz), numel(frequency_Hz));

summaryRows = table();
caseResults = struct();

for b = 1:numel(branches)
    branchName = branches(b);
    fprintf('\n--- Branch: %s ---\n', branchName);

    optionsElastic = mrlfeDefaultSweepOptions(branchName, 'EtaS', 0);
    optionsElastic.mrlfeDisableForwardCache = true;

    tElastic = tic;
    [CpElastic, rawElastic] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, optionsElastic);
    timeElastic = toc(tElastic);

    optionsAtlas = mrlfeDefaultSweepOptions(branchName, 'EtaS', 0);
    optionsAtlas.mrlfeUseDirectViscoAtlas = true;
    optionsAtlas.mrlfeDisableForwardCache = true;
    optionsAtlas.mrlfeA0DPCpScanPoints = 900;
    optionsAtlas.mrlfeA0DPCandidates = 8;
    optionsAtlas.mrlfeA0DPSeedWeight = 0.10;
    optionsAtlas.mrlfeA0DPResidualWeight = 0.45;
    optionsAtlas.mrlfeA0DPJumpWeight = 18.0;
    optionsAtlas.mrlfeA0DPCurvatureWeight = 12.0;
    optionsAtlas.mrlfeResidualTolerance = 1e-3;
    if branchName == "S0Like"
        optionsAtlas.mrlfeViscoS0ModalCpWindow = [0.70, 1.40];
    else
        optionsAtlas.mrlfeViscoA0ModalCpWindow = [0.25, 3.00];
    end

    tAtlas = tic;
    [CpAtlas, rawAtlas] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, optionsAtlas);
    timeAtlas = toc(tAtlas);

    atlasBranch = rawAtlas.branch;
    valid = isfinite(CpElastic(:)) & isfinite(CpAtlas(:));
    rmse = sqrt(mean((CpAtlas(valid) - CpElastic(valid)).^2, 'omitnan'));
    maxAbs = max(abs(CpAtlas(valid) - CpElastic(valid)), [], 'omitnan');
    validFractionElastic = nnz(isfinite(CpElastic(:))) / numel(CpElastic);
    validFractionAtlas = nnz(isfinite(CpAtlas(:))) / numel(CpAtlas);
    validFractionAtlasStrict = nnz(atlasBranch.validCp(:) & isfinite(CpAtlas(:))) / numel(CpAtlas);

    fprintf('  maintained elastic time = %.6g s | valid = %d/%d\n', timeElastic, nnz(isfinite(CpElastic)), numel(CpElastic));
    fprintf('  direct atlas time       = %.6g s | valid finite = %d/%d | valid strict = %d/%d\n', ...
        timeAtlas, nnz(isfinite(CpAtlas)), numel(CpAtlas), nnz(atlasBranch.validCp(:) & isfinite(CpAtlas(:))), numel(CpAtlas));
    fprintf('  direct atlas path       = %s\n', rawAtlas.evaluationPath.path);
    fprintf('  RMSE atlas-elastic      = %.6g m/s\n', rmse);
    fprintf('  max abs atlas-elastic   = %.6g m/s\n', maxAbs);

    T = table(frequency_Hz(:), CpElastic(:), CpAtlas(:), CpAtlas(:) - CpElastic(:), ...
        'VariableNames', {'frequency_Hz','Cp_elastic','Cp_direct_atlas','atlas_minus_elastic'});
    disp(T);

    row = table();
    row.BranchName = branchName;
    row.NumFrequencies = numel(frequency_Hz);
    row.ValidFractionElastic = validFractionElastic;
    row.ValidFractionAtlas = validFractionAtlas;
    row.ValidFractionAtlasStrict = validFractionAtlasStrict;
    row.RMSE_mps = rmse;
    row.MaxAbsDifference_mps = maxAbs;
    row.TimeElastic_s = timeElastic;
    row.TimeAtlas_s = timeAtlas;
    row.EvaluationPath = string(rawAtlas.evaluationPath.path);
    summaryRows = [summaryRows; row]; %#ok<AGROW>

    caseResults(b).branchName = branchName; %#ok<SAGROW>
    caseResults(b).frequency_Hz = frequency_Hz;
    caseResults(b).CpElastic = CpElastic;
    caseResults(b).CpAtlas = CpAtlas;
    caseResults(b).rawElastic = rawElastic;
    caseResults(b).rawAtlas = rawAtlas;
    caseResults(b).atlasBranch = atlasBranch;
    caseResults(b).table = T;
end

fprintf('\nSummary\n');
disp(summaryRows);

assignin('base', 'MRLFEDirectAtlasEtaSZeroDiagnosticSummary', summaryRows);
assignin('base', 'MRLFEDirectAtlasEtaSZeroDiagnosticCases', caseResults);

fprintf('\nInterpretation notes:\n');
fprintf('  - Agreement at etaS = 0 is necessary before using direct atlas as a unified mRLFE route.\n');
fprintf('  - A0Like and S0Like must be assessed separately.\n');
fprintf('  - If etaS = 0 fails or truncates, keep the maintained elastic path.\n');
fprintf('  - If etaS = 0 agrees for A0Like only, restrict any future unification to A0Like.\n');
