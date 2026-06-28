% Diagnose whether atlas routes are ready to become primary mRLFE real-k solvers.
%
% This diagnostic compares the maintained reference-based mRLFE workflow against
% atlas candidates across the minimum policy matrix:
%   A0Like/S0Like, etaS = 0      -> modal atlas continuous and cut
%   A0Like/S0Like, etaS > 0      -> direct viscous atlas
%
% It is diagnostic only. It does not change GUI or solver routing policy.

clear; clc;
startup

fprintf('\n=== mRLFE atlas primary-policy matrix diagnostic ===\n');

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

fprintf('Frequency points: %d | fmin %.6g Hz | fmax %.6g Hz\n', numel(frequency), min(frequency), max(frequency));
fprintf('Material: mu %.3f kPa | nu %.5f | rho %.1f kg/m^3 | thickness %.3f mm | CT %.4g m/s\n', ...
    params.mu/1e3, params.nu, params.rho, params.thickness*1e3, params.CT);

policyOptions = struct();
policyOptions.robustness = "Fast";
policyOptions.branchNames = ["A0Like", "S0Like"];
policyOptions.etaSValues = [0, 0.05];
policyOptions.mrlfeParams = defaultMRLFEParams();
policyOptions.mrlfeParams.fluidDensity = 1000;
policyOptions.mrlfeParams.fluidSoundSpeed = 1500;

% Modal-atlas elastic settings. These match the current A0-like diagnostic
% policy closely enough for comparison while keeping the route opt-in.
policyOptions.mrlfeModalAtlasCpScanPoints = 1200;
policyOptions.mrlfeModalAtlasTopNMinima = 24;
policyOptions.mrlfeModalAtlasMaxLogCpJump = 0.075;
policyOptions.mrlfeModalAtlasCpMinFactor = 0.20;
policyOptions.mrlfeModalAtlasCpMaxFactor = 2.80;
policyOptions.mrlfeModalAtlasCpMaxCeiling = 120;
policyOptions.mrlfeModalAtlasMinBranchPoints = 8;
policyOptions.mrlfeModalAtlasRefineMinima = true;
policyOptions.mrlfeModalAtlasRequireLowStartRank = false;
policyOptions.mrlfeModalAtlasRequireResidualValidity = false;
policyOptions.mrlfeModalAtlasAmbiguityResidualRatio = 4.0;
policyOptions.mrlfeModalAtlasAmbiguityMinCpSeparation = 0.16;
policyOptions.mrlfeModalAtlasAmbiguityMaxGapPoints = 6;
policyOptions.mrlfeModalAtlasAmbiguityPaddingPoints = 1;
policyOptions.mrlfeModalAtlasAmbiguityMinClusterTriggers = 2;

% Direct viscous atlas settings.
policyOptions.mrlfeViscoAtlasCpScanPoints = 900;
policyOptions.mrlfeA0DPCandidates = 8;
policyOptions.mrlfeA0DPRefineCandidates = true;
policyOptions.mrlfeRealKStopAtFirstMissingModalMinimum = true;
policyOptions.mrlfeViscoPreviousCpMaxRelativeJump = 0.18;
policyOptions.mrlfeViscoA0ModalCpWindow = [0.35, 2.50];
policyOptions.mrlfeViscoS0ModalCpWindow = [0.70, 1.40];

[summaryRows, caseResults] = compareMRLFEAtlasPolicy(params, policyOptions);

fprintf('\nPrimary-policy matrix summary\n');
disp(summaryRows);

assignin('base', 'MRLFEAtlasPrimaryPolicySummary', summaryRows);
assignin('base', 'MRLFEAtlasPrimaryPolicyCases', caseResults);
assignin('base', 'MRLFEAtlasPrimaryPolicyOptions', policyOptions);
assignin('base', 'MRLFEAtlasPrimaryPolicyFrequency', frequency);

fprintf('\nInterpretation guide:\n');
fprintf('  - etaS = 0 rows compare maintained elastic real-k vs modal atlas continuous/cut.\n');
fprintf('  - etaS > 0 rows compare maintained reference-based visco real-k vs direct viscous atlas.\n');
fprintf('  - A candidate is not primary-ready if it wins only by speed but loses modal identity, valid coverage, or ambiguity handling.\n');
fprintf('  - Favor conservative ambiguity cuts over automatic jumps to another modal family.\n');
fprintf('  - Do not change GUI routing until A0/S0 and etaS=0/>0 rows satisfy the acceptance criteria.\n');
