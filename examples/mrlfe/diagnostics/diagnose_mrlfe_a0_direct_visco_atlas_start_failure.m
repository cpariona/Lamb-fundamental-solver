% Diagnose A0Like direct-visco atlas start failure.
%
% The primary-policy matrix showed A0Like etaS>0 returning zero valid points
% with FirstModalCut_Hz = 10 Hz. This diagnostic compares branch-specific A0
% policies and reports the first few raw DP outputs before/after modal cutting.

clear; clc;
startup

fprintf('\n=== A0Like direct-visco atlas start-failure diagnostic ===\n');

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
seedOptions.computeA0 = true;
seedOptions.computeS0 = false;
seedOptions.computeMRLFE = false;
seedOptions.computeMRLFERealK = false;
seedOptions.computeMRLFEElasticRealK = false;
seedOptions.computeMRLFEViscoRealK = false;
seedOptions.computeMRLFEComplexK = false;
seedRaw = rlComputeFundamentalLambModes(params, seedOptions);
seedMode = seedRaw.modes.A0;

baseOptions = rlDefaultOptions("Fast");
baseOptions.mrlfeParams = mrlfeParams;

cases = struct([]);
cases(1).Name = "baseline_cut";
cases(1).Policy = struct( ...
    'mrlfeViscoA0StopAtFirstMissingModalMinimum', true, ...
    'mrlfeViscoA0PreviousCpMaxRelativeJump', 0.18, ...
    'mrlfeViscoA0ResidualTolerance', 1e-3, ...
    'mrlfeViscoA0ModalCpWindow', [0.35, 2.50]);
cases(2).Name = "no_start_cut";
cases(2).Policy = struct( ...
    'mrlfeViscoA0StopAtFirstMissingModalMinimum', false, ...
    'mrlfeViscoA0PreviousCpMaxRelativeJump', inf, ...
    'mrlfeViscoA0ResidualTolerance', 1e-3, ...
    'mrlfeViscoA0ModalCpWindow', [0.35, 2.50]);
cases(3).Name = "relaxed_residual";
cases(3).Policy = struct( ...
    'mrlfeViscoA0StopAtFirstMissingModalMinimum', true, ...
    'mrlfeViscoA0PreviousCpMaxRelativeJump', 0.30, ...
    'mrlfeViscoA0ResidualTolerance', 1e-2, ...
    'mrlfeViscoA0ModalCpWindow', [0.25, 3.00]);

summaryRows = table();
caseResults = struct([]);
for iCase = 1:numel(cases)
    policy = cases(iCase).Policy;
    policy.mrlfeViscoAtlasCpScanPoints = 900;
    policy.mrlfeA0DPCandidates = 8;
    policy.mrlfeA0DPRefineCandidates = true;

    options = mrlfeMakeDirectViscoAtlasBranchOptions(baseOptions, "A0Like", policy);
    tCase = tic;
    branch = solveMRLFEViscoBranchAtlas("A0Like", seedMode, material, geometry, mrlfeParams, options);
    elapsed = toc(tCase);

    valid = getBranchValid(branch);
    row = table();
    row.CaseName = cases(iCase).Name;
    row.Elapsed_s = elapsed;
    row.ValidPoints = nnz(valid);
    row.FirstValid_Hz = firstFrequency(frequency, valid);
    row.LastValid_Hz = lastFrequency(frequency, valid);
    row.FirstModalCut_Hz = getFieldOrDefault(branch, 'firstMissingModalMinimumFrequency', nan);
    row.ModalCutReason = string(getFieldOrDefault(branch, 'modalCutReason', "none"));
    row.ResidualTolerance = options.mrlfeResidualTolerance;
    row.PreviousCpMaxRelativeJump = options.mrlfeViscoPreviousCpMaxRelativeJump;
    row.StopAtFirstMissing = options.mrlfeRealKStopAtFirstMissingModalMinimum;
    summaryRows = [summaryRows; row]; %#ok<AGROW>

    caseResults(iCase).name = cases(iCase).Name; %#ok<SAGROW>
    caseResults(iCase).options = options;
    caseResults(iCase).branch = branch;
    caseResults(iCase).firstRows = makeFirstRows(branch, frequency, 12);

    fprintf('\nCase %s | elapsed %.4g s | valid %d/%d | cut %.6g Hz | reason %s\n', ...
        cases(iCase).Name, elapsed, nnz(valid), numel(valid), row.FirstModalCut_Hz, row.ModalCutReason);
    disp(caseResults(iCase).firstRows);
end

fprintf('\nA0 start-failure summary\n');
disp(summaryRows);

assignin('base', 'MRLFEA0DirectViscoAtlasStartFailureSummary', summaryRows);
assignin('base', 'MRLFEA0DirectViscoAtlasStartFailureCases', caseResults);
assignin('base', 'MRLFEA0DirectViscoAtlasFrequency', frequency);

fprintf('\nInterpretation guide:\n');
fprintf('  - If baseline_cut cuts at 10 Hz but no_start_cut has finite Cp, the failure is policy-gating, not candidate generation.\n');
fprintf('  - If no_start_cut also has no finite Cp, inspect candidateIndex/residual/Cp in firstRows.\n');
fprintf('  - If relaxed_residual recovers early points, the residual tolerance is too strict for A0 viscous atlas.\n');

function valid = getBranchValid(branch)
cp = branch.Cp(:);
valid = isfinite(cp) & cp > 0;
if isfield(branch, 'validCp')
    valid = valid & logical(branch.validCp(:));
elseif isfield(branch, 'valid')
    valid = valid & logical(branch.valid(:));
end
end

function rows = makeFirstRows(branch, frequency, nRows)
n = min(nRows, numel(frequency));
rows = table();
rows.Frequency_Hz = frequency(1:n).';
rows.Cp_mps = vectorField(branch, 'Cp', n);
rows.Residual = vectorField(branch, 'residual', n);
rows.CandidateIndex = vectorField(branch, 'candidateIndex', n);
rows.CandidateRank = vectorField(branch, 'candidateRank', n);
rows.ValidCp = logicalVectorField(branch, 'validCp', n);
rows.Valid = logicalVectorField(branch, 'valid', n);
end

function value = vectorField(s, fieldName, n)
value = nan(n, 1);
if isstruct(s) && isfield(s, fieldName)
    x = s.(fieldName);
    if numel(x) >= n
        value = x(1:n);
        value = value(:);
    end
end
end

function value = logicalVectorField(s, fieldName, n)
value = false(n, 1);
if isstruct(s) && isfield(s, fieldName)
    x = logical(s.(fieldName));
    if numel(x) >= n
        value = x(1:n);
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
