function out = solveMRLFEAtlasUnified(frequency, material, geometry, seedModes, mrlfeParams, options)
%SOLVEMRLFEATLASUNIFIED Unified atlas-based real-k mRLFE solver.

if nargin < 6 || isempty(options)
    options = struct();
end
frequency = frequency(:);
t0 = tic;

mrlfeParams.solveComplexK = false;
if ~isfield(mrlfeParams, 'etaS') || isempty(mrlfeParams.etaS)
    mrlfeParams.etaS = 0;
end
if ~isfield(mrlfeParams, 'etaL') || isempty(mrlfeParams.etaL)
    mrlfeParams.etaL = 0;
end
if ~isfield(mrlfeParams, 'useComplexLambda') || isempty(mrlfeParams.useComplexLambda)
    mrlfeParams.useComplexLambda = false;
end

computeA0 = getOption(options, 'mrlfeComputeA0Like', true);
computeS0 = getOption(options, 'mrlfeComputeS0Like', true);
isViscous = mrlfeParams.etaS > 0;

out = struct();
out.modelName = "mRLFE";
out.variant = "real-k-atlas-unified";
out.description = "Unified atlas-based real-k mRLFE solver.";
out.parameters = mrlfeParams;
out.requestedBranches = struct('A0Like', logical(computeA0), 'S0Like', logical(computeS0));
out.frequency = frequency;
out.tracking = struct('usedInternalGrid', false, 'requestedFrequency', frequency, 'trackingFrequency', frequency);
out.branches = struct();
out.atlasUnified = struct('usesElasticMRLFEReference', false, 'seedStrategy', "RayleighLambOrPhysicalSynthetic", 'isViscous', isViscous);

if computeA0
    seedA0 = mrlfeMakePhysicalSeedMode("A0Like", frequency, material, geometry, seedModes);
    out.branches.A0Like = solveOneAtlasBranch("A0Like", seedA0, material, geometry, mrlfeParams, options, isViscous);
end
if computeS0
    seedS0 = mrlfeMakePhysicalSeedMode("S0Like", frequency, material, geometry, seedModes);
    out.branches.S0Like = solveOneAtlasBranch("S0Like", seedS0, material, geometry, mrlfeParams, options, isViscous);
end

out.diagnostics = summarizeAtlasUnified(out, toc(t0));
end

function branch = solveOneAtlasBranch(branchName, seedMode, material, geometry, mrlfeParams, options, isViscous)
if isViscous
    opt = makeViscousOptions(branchName, options);
    branch = solveMRLFEViscoBranchAtlas(branchName, seedMode, material, geometry, mrlfeParams, opt);
    if string(branchName) == "A0Like"
        [branch, cut] = mrlfeApplyDelayedViscoModalCut(branch, opt);
        branch.delayedViscoModalCut = cut;
        branch.atlasUnifiedPolicy = "viscousA0DelayedCut";
    else
        [branch, cut] = mrlfeApplyDelayedViscoModalCut(branch, opt);
        branch.delayedViscoModalCut = cut;
        branch.atlasUnifiedPolicy = "viscousS0DelayedContinuationCut";
    end
else
    opt = makeElasticOptions(branchName, options);
    branch = solveMRLFEBranchModalAtlas(branchName, seedMode, material, geometry, mrlfeParams, opt);
    branch.atlasUnifiedPolicy = "elasticModalAtlas";
end
branch.solverRoute = "atlasUnified";
branch.seedMode = seedMode;
end

function opt = makeElasticOptions(branchName, options)
opt = options;
opt.mrlfeModalAtlasApplyAmbiguityCut = getOption(options, 'mrlfeModalAtlasApplyAmbiguityCut', true);
opt.mrlfeModalAtlasCpScanPoints = getOption(options, 'mrlfeModalAtlasCpScanPoints', 1200);
opt.mrlfeModalAtlasTopNMinima = getOption(options, 'mrlfeModalAtlasTopNMinima', 24);
opt.mrlfeModalAtlasMinBranchPoints = getOption(options, 'mrlfeModalAtlasMinBranchPoints', 8);
opt.mrlfeModalAtlasMaxLogCpJump = getOption(options, 'mrlfeModalAtlasMaxLogCpJump', 0.075);
if string(branchName) == "S0Like"
    opt.mrlfeModalAtlasCpMinFactor = getOption(options, 'mrlfeModalAtlasS0CpMinFactor', 0.65);
    opt.mrlfeModalAtlasCpMaxFactor = getOption(options, 'mrlfeModalAtlasS0CpMaxFactor', 1.55);
else
    opt.mrlfeModalAtlasCpMinFactor = getOption(options, 'mrlfeModalAtlasA0CpMinFactor', 0.20);
    opt.mrlfeModalAtlasCpMaxFactor = getOption(options, 'mrlfeModalAtlasA0CpMaxFactor', 2.80);
end
end

function opt = makeViscousOptions(branchName, options)
opt = mrlfeMakeDirectViscoAtlasBranchOptions(options, branchName, options);
opt.mrlfeA0DPCandidates = getOption(options, 'mrlfeA0DPCandidates', 8);
opt.mrlfeA0DPCpScanPoints = getOption(options, 'mrlfeViscoAtlasCpScanPoints', getOption(options, 'mrlfeA0DPCpScanPoints', 900));
opt.mrlfeA0DPEdgeGuardPoints = getOption(options, 'mrlfeA0DPEdgeGuardPoints', 6);
opt.mrlfeA0DPRefineCandidates = getOption(options, 'mrlfeA0DPRefineCandidates', true);
opt.mrlfeResidualTolerance = max(getOption(options, 'mrlfeResidualTolerance', 1e-4), 1e-3);
if string(branchName) == "A0Like"
    opt.mrlfeRealKStopAtFirstMissingModalMinimum = false;
    opt.mrlfeViscoA0StopAtFirstMissingModalMinimum = false;
    opt.mrlfeViscoA0PreviousCpMaxRelativeJump = inf;
    opt.mrlfeDelayedCutMinValidRun = getOption(options, 'mrlfeDelayedCutMinValidRun', 8);
    opt.mrlfeDelayedCutPreviousCpMaxRelativeJump = getOption(options, 'mrlfeDelayedCutPreviousCpMaxRelativeJump', 0.18);
    opt.mrlfeDelayedCutResidualTolerance = getOption(options, 'mrlfeDelayedCutResidualTolerance', 1e-3);
else
    % S0Like uses RL-S0 only as a fast branch-scale seed. Once the branch is
    % found, tracking should prefer the previous selected mRLFE candidate over
    % returning to the RL-S0 curve, which can drift toward CT at high frequency.
    opt.mrlfeA0DPJumpWeight = getOption(options, 'mrlfeViscoS0DPJumpWeight', 55.0);
    opt.mrlfeA0DPCurvatureWeight = getOption(options, 'mrlfeViscoS0DPCurvatureWeight', 45.0);
    opt.mrlfeA0DPSeedWeight = getOption(options, 'mrlfeViscoS0DPSeedWeight', 0.03);
    opt.mrlfeA0DPResidualWeight = getOption(options, 'mrlfeViscoS0DPResidualWeight', 0.35);
    opt.mrlfeA0DPMaxJumpSoft = getOption(options, 'mrlfeViscoS0DPMaxJumpSoft', 0.08);
    opt.mrlfeA0DPValidationMaxCpJumpRelative = getOption(options, 'mrlfeViscoS0DPValidationMaxCpJumpRelative', 0.18);
    opt.mrlfeA0DPValidationMaxCpPredictionError = getOption(options, 'mrlfeViscoS0DPValidationMaxCpPredictionError', 0.18);
    opt.mrlfeRealKStopAtFirstMissingModalMinimum = false;
    opt.mrlfeViscoS0StopAtFirstMissingModalMinimum = false;
    opt.mrlfeDelayedCutMinValidRun = getOption(options, 'mrlfeViscoS0DelayedCutMinValidRun', 8);
    opt.mrlfeDelayedCutPreviousCpMaxRelativeJump = getOption(options, 'mrlfeViscoS0DelayedCutPreviousCpMaxRelativeJump', 0.18);
    opt.mrlfeDelayedCutResidualTolerance = getOption(options, 'mrlfeViscoS0DelayedCutResidualTolerance', 1e-3);
    opt.mrlfeViscoS0PreviousCpMaxRelativeJump = getOption(options, 'mrlfeViscoS0PreviousCpMaxRelativeJump', 0.18);
    opt.mrlfeViscoS0ModalCpWindow = getOption(options, 'mrlfeViscoS0ModalCpWindow', [0.70, 1.40]);
end
end

function d = summarizeAtlasUnified(out, elapsed)
d = struct();
d.elapsedSeconds = elapsed;
d.variant = out.variant;
d.branchNames = string(fieldnames(out.branches));
d.usedInternalTrackingGrid = false;
d.requestedPointCount = numel(out.frequency);
d.trackingPointCount = numel(out.frequency);
d.summary = struct();
for i = 1:numel(d.branchNames)
    name = char(d.branchNames(i));
    b = out.branches.(name);
    valid = branchValid(b);
    s = struct();
    s.validPoints = nnz(valid);
    s.totalPoints = numel(b.Cp);
    s.maxCpJumpRelative = maxRelativeJump(b.Cp(valid));
    s.policy = b.atlasUnifiedPolicy;
    d.summary.(name) = s;
end
end

function valid = branchValid(b)
valid = isfinite(b.Cp(:)) & b.Cp(:) > 0;
if isfield(b, 'validCp')
    valid = valid & logical(b.validCp(:));
elseif isfield(b, 'valid')
    valid = valid & logical(b.valid(:));
end
end

function y = maxRelativeJump(x)
x = x(:);
x = x(isfinite(x) & x > 0);
if numel(x) < 2
    y = 0;
else
    y = max(abs(diff(x)) ./ max(abs(x(1:end-1)), eps));
end
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
