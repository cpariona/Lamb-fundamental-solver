clear; clc;
startup

fprintf('\nRunning mRLFE FitTool public-solver route guard test...\n');
fprintf('------------------------------------------------------\n');

repoRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
evaluatorPath = fullfile(repoRoot, 'analysis', 'mrlfe', 'mrlfeEvaluateFitModel.m');
adapterPath = fullfile(repoRoot, 'app', 'adapters', 'guiFitMRLFESolver.m');
fitWorkflowPath = fullfile(repoRoot, 'analysis', 'mrlfe', 'mrlfeFitDispersionData.m');

evaluatorText = string(fileread(evaluatorPath));
adapterText = string(fileread(adapterPath));
workflowText = string(fileread(fitWorkflowPath));

assert(contains(evaluatorText, "mrlfeSolve"), ...
    'mRLFE fitting evaluator must call the public mrlfeSolve API.');
assert(~contains(evaluatorText, "mrlfeEvaluateAtlasFitModel"), ...
    'mRLFE fitting evaluator must not call the old atlas evaluator.');
assert(~contains(adapterText + workflowText + evaluatorText, "mrlfeEvaluateAtlasFitModel"), ...
    'Maintained FitTool fitting path must not reference the old atlas evaluator.');
assert(~contains(adapterText, "solveMRLFE") && ~contains(adapterText, "computeMRLFE") && ...
    ~contains(adapterText, "mrlfeTrackBranchAdaptive"), ...
    'FitTool adapter must not contain low-level mRLFE solver logic.');

params = mrlfeDefaultSweepParams();
params.mu = 75e3;
params.etaS = 0.05;
frequency_Hz = linspace(1000, 5000, 8).';
options = mrlfeDefaultSweepOptions("A0Like", 'EtaS', params.etaS, ...
    'UseUnifiedAtlasRoute', true, 'A0Policy', "adaptivePhysicalTail");
options.mrlfeUseAtlasFitRoute = true;

[Cp_mps, raw] = mrlfeEvaluateFitModel(params, frequency_Hz, "A0Like", options);
assert(any(isfinite(Cp_mps)), 'Public-solver fitting evaluation must return finite Cp values.');
assert(isfield(raw, 'modelResult'), 'Compatibility raw result must preserve the public model result.');
assert(raw.evaluationPath.usedPublicSolver == true, 'Fitting evaluator must report public-solver use.');
assert(raw.modelResult.execution.effectivePreset == "fast", 'Fit route must use public fast preset.');
assert(raw.modelResult.fallback.applied == false, 'Fit route must not apply fallback.');
assert(any(raw.modelResult.execution.internalEngine == ["elastic_adaptive", "viscoelastic_adaptive"]), ...
    'Fit route must report a neutral public engine name.');

fprintf('Route: %s | public preset: %s | engine: %s\n', ...
    raw.evaluationPath.path, raw.modelResult.execution.effectivePreset, ...
    raw.modelResult.execution.internalEngine);
fprintf('\nmRLFE FitTool public-solver route guard test passed.\n');
