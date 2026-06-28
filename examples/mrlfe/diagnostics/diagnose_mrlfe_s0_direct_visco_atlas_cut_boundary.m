% Diagnose S0Like direct-visco atlas cut boundary.
%
% The primary-policy matrix showed S0Like etaS>0 matching the maintained branch
% where valid, but cutting around 7.45 kHz. This diagnostic compares S0-specific
% cut/jump/window policies around that boundary.

clear; clc;
startup

fprintf('\n=== S0Like direct-visco atlas cut-boundary diagnostic ===\n');

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
if isfield(geometry, 'halfThickness')
    geometry = rmfield(geometry, 'halfThickness');
end
frequency = rlBuildFrequencyVector(params);

mrlfeParams = defaultMRLFEParams();
mrlfeParams.fluidDensity = 1000;
mrlfeParams.fluidSoundSpeed = 1500;
mrlfeParams.etaS = 0.05;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
mrlfeParams.solveComplexK = false;

seedOptions = rlDefaultOptions("Fast");
seedOptions.computeA0 = false;
seedOptions.computeS0 = true;
seedOptions.computeMRLFE = false;
seedOptions.computeMRLFERealK = false;
seedOptions.computeMRLFEElasticRealK = false;
seedOptions.computeMRLFEViscoRealK = false;
seedOptions.computeMRLFEComplexK = false;
seedRaw = rlComputeFundamentalLambModes(params, seedOptions);
seedMode = seedRaw.modes.S0;

baseOptions = rlDefaultOptions("Fast");
baseOptions.mrlfeParams = mrlfeParams;

cases = struct([]);
cases(1).Name = "baseline_s0_cut";
cases(1).Policy = struct( ...
    'mrlfeViscoS0StopAtFirstMissingModalMinimum', true, ...
    'mrlfeViscoS0PreviousCpMaxRelativeJump', 0.18, ...
    'mrlfeViscoS0ResidualTolerance', 1e-3, ...
    'mrlfeViscoS0ModalCpWindow', [0.70, 1.40]);
cases(2).Name = "s0_relaxed_jump";
cases(2).Policy = struct( ...
    'mrlfeViscoS0StopAtFirstMissingModalMinimum', true, ...
    'mrlfeViscoS0PreviousCpMaxRelativeJump', 0.35, ...
    'mrlfeViscoS0ResidualTolerance', 1e-3, ...
    'mrlfeViscoS0ModalCpWindow', [0.65, 1.50]);
cases(3).Name = "s0_no_tail_cut";
cases(3).Policy = struct( ...
    'mrlfeViscoS0StopAtFirstMissingModalMinimum', false, ...
    'mrlfeViscoS0PreviousCpMaxRelativeJump', inf, ...
    'mrlfeViscoS0ResidualTolerance', 1e-3, ...
    'mrlfeViscoS0ModalCpWindow', [0.65, 1.50]);

summaryRows = table();
caseResults = struct([]);
for iCase = 1:numel(cases)
    policy = cases(iCase).Policy;
    policy.mrlfeViscoAtlasCpScanPoints = 900;
    policy.mrlfeA0DPCandidates = 8;
    policy.mrlfeA0DPRefineCandidates = true;

    options = mrlfeMakeDirectViscoAtlasBranchOptions(baseOptions, "S0Like", policy);
    tCase = tic;
    branch = solveMRLFEViscoBranchAtlas("S0Like", seedMode, material, geometry, mrlfeParams, options);
    elapsed = toc(tCase);

    valid = getBranchValid(branch);
    cutFrequency = getFieldOrDefault(branch, 'firstMissingModalMinimumFrequency', nan);
    row = table();
    row.CaseName = cases(iCase).Name;
    row.Elapsed_s = elapsed;
    row.ValidPoints = nnz(valid);
    row.FirstValid_Hz = firstFrequency(frequency, valid);
    row.LastValid_Hz = lastFrequency(frequency, valid);
    row.FirstModalCut_Hz = cutFrequency;
    row.ModalCutReason = string(getFieldOrDefault(branch, 'modalCutReason', "none"));
    row.ResidualTolerance = options.mrlfeResidualTolerance;
    row.PreviousCpMaxRelativeJump = options.mrlfeViscoPreviousCpMaxRelativeJump;
    row.StopAtFirstMissing = options.mrlfeRealKStopAtFirstMissingModalMinimum;
    summaryRows = [summaryRows; row]; %#ok<AGROW>

    caseResults(iCase).name = cases(iCase).Name; %#ok<SAGROW>
    caseResults(iCase).options = options;
    caseResults(iCase).branch = branch;
    caseResults(iCase).boundaryRows = makeBoundaryRows(branch, frequency, cutFrequency, 8);

    fprintf('\nCase %s | elapsed %.4g s | valid %d/%d | cut %.6g Hz | reason %s\n', ...
        cases(iCase).Name, elapsed, nnz(valid), numel(valid), row.FirstModalCut_Hz, row.ModalCutReason);
    disp(caseResults(iCase).boundaryRows);
end

fprintf('\nS0 cut-boundary summary\n');
disp(summaryRows);

assignin('base', 'MRLFES0DirectViscoAtlasCutBoundarySummary', summaryRows);
assignin('base', 'MRLFES0DirectViscoAtlasCutBoundaryCases', caseResults);
assignin('base', 'MRLFES0DirectViscoAtlasFrequency', frequency);

fprintf('\nInterpretation guide:\n');
fprintf('  - If s0_relaxed_jump extends the valid band without large jumps, the 0.18 jump limit is too strict for S0.\n');
fprintf('  - If s0_no_tail_cut remains smooth past the baseline cut, the stop-at-first-missing policy is too conservative.\n');
fprintf('  - S0 must be assessed independently because the original atlas validation was A0-focused.\n');

function valid = getBranchValid(branch)
cp = branch.Cp(:);
valid = isfinite(cp) & cp > 0;
if isfield(branch, 'validCp')
    valid = valid & logical(branch.validCp(:));
elseif isfield(branch, 'valid')
    valid = valid & logical(branch.valid(:));
end
end

function rows = makeBoundaryRows(branch, frequency, cutFrequency, halfWindow)
if ~isfinite(cutFrequency)
    center = min(numel(frequency), max(1, round(numel(frequency)/2)));
else
    [~, center] = min(abs(frequency(:) - cutFrequency));
end
idx1 = max(1, center - halfWindow);
idx2 = min(numel(frequency), center + halfWindow);
idx = idx1:idx2;
rows = table();
rows.Index = idx(:);
rows.Frequency_Hz = frequency(idx).';
rows.Cp_mps = vectorField(branch, 'Cp', idx);
rows.Residual = vectorField(branch, 'residual', idx);
rows.CandidateIndex = vectorField(branch, 'candidateIndex', idx);
rows.CandidateRank = vectorField(branch, 'candidateRank', idx);
rows.ValidCp = logicalVectorField(branch, 'validCp', idx);
rows.Valid = logicalVectorField(branch, 'valid', idx);
end

function value = vectorField(s, fieldName, idx)
value = nan(numel(idx), 1);
if isstruct(s) && isfield(s, fieldName)
    x = s.(fieldName);
    if numel(x) >= max(idx)
        value = x(idx);
        value = value(:);
    end
end
end

function value = logicalVectorField(s, fieldName, idx)
value = false(numel(idx), 1);
if isstruct(s) && isfield(s, fieldName)
    x = logical(s.(fieldName));
    if numel(x) >= max(idx)
        value = x(idx);
        value = value(:);
    end
end
end

function value = firstFrequency(frequency, mask)
idx = find(mask(:), 1, 'first');
if isempty(idx)
    value = nan;
else
    value = frequency(idx);
end
end

function value = lastFrequency(frequency, mask)
idx = find(mask(:), 1, 'last');
if isempty(idx)
    value = nan;
else
    value = frequency(idx);
end
end

function value = getFieldOrDefault(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end
