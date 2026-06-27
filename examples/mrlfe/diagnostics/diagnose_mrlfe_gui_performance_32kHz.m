% Diagnose mRLFE performance for the main GUI-style 32 kHz case.
%
% This script separates timing for RL-only seeds, mRLFE elastic real-k, mRLFE
% viscous real-k, A0-like, S0-like, and combined branches. It is diagnostic
% only and does not change solver policy.

clear; clc;
startup

fprintf('\n=== mRLFE GUI performance diagnostic, 32 kHz case ===\n');

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
fprintf('Material: mu %.3f kPa | nu %.5f | rho %.1f kg/m^3 | 2h %.3f mm | CT %.4g m/s\n', ...
    params.mu/1e3, params.nu, params.rho, params.thickness*1e3, params.CT);

robustnessList = ["Fast", "Balanced"];
etaSList = [0, 0.05];
branchCases = makeBranchCases();
summaryRows = table();
caseResults = struct();
caseIndex = 0;

for iRobust = 1:numel(robustnessList)
    robustness = robustnessList(iRobust);
    fprintf('\nRobustness: %s\n', robustness);

    baseOptions = rlDefaultOptions(robustness);
    baseOptions.mrlfeParams = defaultMRLFEParams();
    baseOptions.mrlfeParams.fluidDensity = 1000;
    baseOptions.mrlfeParams.fluidSoundSpeed = 1500;
    baseOptions.mrlfeParams.etaL = 0;
    baseOptions.mrlfeParams.useComplexLambda = false;
    baseOptions.computeMRLFE = false;
    baseOptions.computeMRLFEComplexK = false;

    % RL seed timing, A0 and S0 independently.
    rlA0Options = baseOptions;
    rlA0Options.computeA0 = true;
    rlA0Options.computeS0 = false;
    rlA0Options.computeMRLFERealK = false;
    rlA0Options.computeMRLFEElasticRealK = false;
    rlA0Options.computeMRLFEViscoRealK = false;
    [timeRLA0, rawRLA0] = timedRun(params, rlA0Options);

    rlS0Options = baseOptions;
    rlS0Options.computeA0 = false;
    rlS0Options.computeS0 = true;
    rlS0Options.computeMRLFERealK = false;
    rlS0Options.computeMRLFEElasticRealK = false;
    rlS0Options.computeMRLFEViscoRealK = false;
    [timeRLS0, rawRLS0] = timedRun(params, rlS0Options);

    fprintf('  RL A0 seed: %.6g s | valid %d/%d\n', timeRLA0, countModeValid(rawRLA0, 'A0'), numel(frequency));
    fprintf('  RL S0 seed: %.6g s | valid %d/%d\n', timeRLS0, countModeValid(rawRLS0, 'S0'), numel(frequency));

    for iEta = 1:numel(etaSList)
        etaS = etaSList(iEta);
        for iBranch = 1:height(branchCases)
            branchCase = branchCases(iBranch, :);
            options = baseOptions;
            options.computeA0 = logical(branchCase.A0Like);
            options.computeS0 = logical(branchCase.S0Like);
            options.computeMRLFERealK = true;
            options.computeMRLFEElasticRealK = true;
            options.computeMRLFEViscoRealK = etaS > 0;
            options.mrlfeComputeA0Like = logical(branchCase.A0Like);
            options.mrlfeComputeS0Like = logical(branchCase.S0Like);
            options.mrlfeParams.etaS = etaS;

            label = sprintf('%s | etaS %.4g | %s', robustness, etaS, branchCase.Label);
            fprintf('\n  Case: %s\n', label);

            [elapsed, raw] = timedRun(params, options);
            caseIndex = caseIndex + 1;
            caseResults(caseIndex).label = label; %#ok<SAGROW>
            caseResults(caseIndex).options = options;
            caseResults(caseIndex).raw = raw;
            caseResults(caseIndex).elapsed = elapsed;

            row = summarizeRun(raw, label, robustness, etaS, branchCase, elapsed, numel(frequency), timeRLA0, timeRLS0);
            summaryRows = [summaryRows; row]; %#ok<AGROW>
            fprintf('    elapsed %.6g s | mRLFE A0 valid %d/%d | mRLFE S0 valid %d/%d\n', ...
                elapsed, row.A0LikeValidPoints, row.NumFrequencyPoints, row.S0LikeValidPoints, row.NumFrequencyPoints);
        end
    end
end

fprintf('\nSummary\n');
disp(summaryRows);

assignin('base', 'MRLFEGuiPerformance32kHzSummary', summaryRows);
assignin('base', 'MRLFEGuiPerformance32kHzCases', caseResults);
assignin('base', 'MRLFEGuiPerformance32kHzFrequency', frequency);

fprintf('\nInterpretation guide:\n');
fprintf('  - If elapsed scales mainly with NumFrequencyPoints, reduce GUI auto points or add preview mode.\n');
fprintf('  - If S0Like dominates, keep S0Like opt-in and consider a separate S0 tracker optimization.\n');
fprintf('  - If etaS>0 roughly doubles etaS=0, the cost is elastic reference plus viscous tracking.\n');
fprintf('  - If repeated etaS>0 runs remain slow, cache compatibility or reference reuse should be inspected.\n');

function branchCases = makeBranchCases()
branchCases = table();
branchCases.Label = ["A0Like only"; "S0Like only"; "A0Like + S0Like"];
branchCases.A0Like = [true; false; true];
branchCases.S0Like = [false; true; true];
end

function [elapsed, raw] = timedRun(params, options)
ticHandle = tic;
raw = rlComputeFundamentalLambModes(params, options);
elapsed = toc(ticHandle);
end

function n = countModeValid(raw, modeName)
n = 0;
if isfield(raw, 'modes') && isfield(raw.modes, modeName)
    mode = raw.modes.(modeName);
    if isfield(mode, 'valid')
        n = nnz(mode.valid);
    elseif isfield(mode, 'Cp')
        n = nnz(isfinite(mode.Cp));
    end
end
end

function row = summarizeRun(raw, label, robustness, etaS, branchCase, elapsed, nFreq, timeRLA0, timeRLS0)
row = table();
row.Label = string(label);
row.Robustness = string(robustness);
row.EtaS_Pa_s = etaS;
row.A0LikeRequested = logical(branchCase.A0Like);
row.S0LikeRequested = logical(branchCase.S0Like);
row.NumFrequencyPoints = nFreq;
row.Elapsed_s = elapsed;
row.RLA0Seed_s = timeRLA0;
row.RLS0Seed_s = timeRLS0;
row.A0LikeValidPoints = countMRLFEBranchValid(raw, 'A0Like');
row.S0LikeValidPoints = countMRLFEBranchValid(raw, 'S0Like');
row.InternalModelList = internalModelList(raw);
end

function n = countMRLFEBranchValid(raw, branchName)
n = 0;
if ~isfield(raw, 'models') || ~isfield(raw.models, 'mRLFERealK')
    return;
end
model = raw.models.mRLFERealK;
if ~isfield(model, 'branches') || ~isfield(model.branches, branchName)
    return;
end
branch = model.branches.(branchName);
if isfield(branch, 'validCp')
    n = nnz(branch.validCp(:) & isfinite(branch.Cp(:)));
elseif isfield(branch, 'valid')
    n = nnz(branch.valid(:) & isfinite(branch.Cp(:)));
elseif isfield(branch, 'Cp')
    n = nnz(isfinite(branch.Cp(:)));
end
end

function value = internalModelList(raw)
if isfield(raw, 'models')
    value = strjoin(string(fieldnames(raw.models)), ', ');
else
    value = "";
end
end
