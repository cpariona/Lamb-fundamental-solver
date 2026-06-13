clear; clc;
startup

% Smoke test for the current Li 2024 strict-A0 atlas-branch solver.
% This is intentionally lightweight: it verifies API availability, basic
% execution, reliability output, and the strict-A0 policy fields.

params = struct();
params.R = 7.8e-3;
params.thickness = 550e-6;
params.mu = 50e3;
params.k1 = 25e3;
params.k2 = 100;
params.rho = 1060;
params.rhoF = 1000;
params.fluidBulkModulus = 2.2e9;
params.frequency = logspace(log10(300), log10(15e3), 35);
params.IOP = 15 * 133.322;

options = defaultLi2024AcoustoelasticOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.usePhysicalCpWindow = false;
options.atlasNumYPoints = 300;
options.atlasTopNMinima = 12;
options.atlasBranchPolicy = "strictA0";

result = solveDispersionIOPHGOAtlasBranch_Li2024(params, options);
resolvedOptions = result.options;

assert(isstruct(result), 'Result must be a struct.');
assert(isfield(result, 'Cp'), 'Result must contain Cp.');
assert(isfield(result, 'validCp'), 'Result must contain validCp.');
assert(isfield(result, 'reliability'), 'Result must contain reliability.');
assert(isfield(result, 'options'), 'Result must contain resolved solver options.');
assert(numel(result.Cp) == numel(params.frequency), 'Cp length must match frequency length.');
assert(numel(result.validCp) == numel(params.frequency), 'validCp length must match frequency length.');
assert(any(result.validCp), 'At least one phase-speed point must be valid.');
assert(result.reliability.PolicyName == "strictA0", 'PolicyName must be strictA0.');
assert(result.reliability.ValidPoints == nnz(result.validCp), 'Reliability valid-point count mismatch.');
assert(result.reliability.ValidFraction > 0, 'ValidFraction must be positive.');
assert(result.reliability.A0StartFilterPassed == true, 'Selected branch must pass the A0 start filter.');
assert(result.reliability.SelectionFallbackUsed == false, 'Smoke test should not require fallback selection.');
assert(result.reliability.YStart <= resolvedOptions.atlasMaxStartY, 'YStart must satisfy strict-A0 filter.');
assert(result.reliability.StartRank <= resolvedOptions.atlasMaxStartRank, 'StartRank must satisfy strict-A0 filter.');

fprintf('test_li2024_strictA0_smoke passed. Valid points: %d/%d. Last valid frequency: %.3f kHz.\n', ...
    result.reliability.ValidPoints, result.reliability.TotalPoints, result.reliability.LastValidFrequency_kHz);
