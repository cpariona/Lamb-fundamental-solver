% TEMPORARY_DIAGNOSTIC
function summary = diagnose_mrlfe_valley_fallback_overlap(varargin)
%DIAGNOSE_MRLFE_VALLEY_FALLBACK_OVERLAP Inspect fallback/local-minimum overlap.

p = inputParser;
p.addParameter('WriteCsv', true, @(x)islogical(x) && isscalar(x));
p.parse(varargin{:});
writeCsv = p.Results.WriteCsv;

repoRoot = findRepositoryRoot(mfilename('fullpath'));
originalFolder = pwd;
originalPath = path;
cleanup = onCleanup(@() restoreSession(originalFolder, originalPath)); %#ok<NASGU>
cd(repoRoot);
startup;

request = buildRequest();
selected = runPolicy(request, false);
refineAll = runPolicy(request, true);

bSel = selected.debug.solverResult.branchSolve;
bAll = refineAll.debug.solverResult.branchSolve;
frequency = bSel.frequency(:);
valid = bSel.validCp(:) & bAll.validCp(:) & isfinite(bSel.Cp(:)) & isfinite(bAll.Cp(:));
delta = abs(bSel.Cp(:) - bAll.Cp(:));
j = find(valid & delta > 1e-10, 1, 'first');
if isempty(j)
    error('mrlfe:DiagnosticNoDivergence', 'No selected-only/refine-all divergence found.');
end

tracker = bSel.dpOptions;
center = bSel.adaptiveCenterCp(j);
window = bSel.adaptiveWindowUsed(j);
cpMin = max(tracker.cpMinFloor, center * (1-window));
cpMax = min(tracker.cpMaxCeiling, center * (1+window));
cpScan = linspace(cpMin, cpMax, tracker.cpScanPoints);

configuration = mrlfeResolveConfiguration(request);
problem = mrlfeBuildProblem(configuration);
params = configuration.internalOptions.mrlfeParams;
params.etaS = request.material.etaS_Pas;
params.solveComplexK = false;
params.etaL = 0;
params.useComplexLambda = false;
omega = 2*pi*frequency(j);
residual = computeResidual(cpScan, omega, problem.material, problem.geometry, params);

idx = findLocalMinima(residual, tracker.edgeGuardPoints);
if isempty(idx)
    error('mrlfe:DiagnosticNoStrictMinimum', 'No strict local minimum found.');
end
strictScore = normalScore(cpScan(idx), residual(idx), center, tracker);
[~, kStrict] = min(strictScore);
strictIndex = idx(kStrict);
strictDiscreteCp = cpScan(strictIndex);
strictDiscreteResidual = residual(strictIndex);

objective = @(cp)mrlfeResidual(omega/cp, omega, problem.material, problem.geometry, params);
opt = optimset('Display','off','TolX',tracker.refineTolX, ...
    'MaxIter',tracker.refineMaxIter,'MaxFunEvals',tracker.refineMaxFunEvals);
lower = cpScan(strictIndex-1);
upper = cpScan(strictIndex+1);
[strictRefinedCp, strictRefinedResidual] = fminbnd(objective, lower, upper, opt);
strictRefinedScore = normalScore(strictRefinedCp, strictRefinedResidual, center, tracker);

fallbackMask = isfinite(residual) & residual > 0 & residual <= tracker.valleyFallbackResidualTolerance;
fallbackMask = fallbackMask & abs(cpScan-center)./max(abs(center),eps) <= tracker.valleyFallbackRelativeWindow;
fallbackIdx = find(fallbackMask);
if isempty(fallbackIdx)
    fallbackCp = NaN;
    fallbackResidual = NaN;
    fallbackScore = NaN;
else
    fallbackChoiceScore = tracker.valleyFallbackResidualWeight .* ...
        log10(max(residual(fallbackIdx), tracker.residualFloor)) + ...
        tracker.valleyFallbackPredictionWeight .* ...
        (abs(cpScan(fallbackIdx)-center)./max(abs(center),eps)).^2;
    [~, kFallback] = min(fallbackChoiceScore);
    fallbackIndex = fallbackIdx(kFallback);
    fallbackCp = cpScan(fallbackIndex);
    fallbackResidual = residual(fallbackIndex);
    fallbackScore = normalScore(fallbackCp, fallbackResidual, center, tracker);
end

summary = table( ...
    j, frequency(j), center, window, tracker.cpScanPoints, numel(idx), ...
    string(bSel.candidateType(j)), string(bAll.candidateType(j)), ...
    bSel.adaptiveCandidateCount(j), bAll.adaptiveCandidateCount(j), ...
    bSel.Cp(j), bAll.Cp(j), ...
    strictDiscreteCp, strictRefinedCp, fallbackCp, ...
    strictDiscreteResidual, strictRefinedResidual, fallbackResidual, ...
    normalScore(strictDiscreteCp, strictDiscreteResidual, center, tracker), ...
    strictRefinedScore, fallbackScore, ...
    abs(fallbackCp-strictDiscreteCp), abs(fallbackCp-strictRefinedCp), ...
    'VariableNames', {'SolveIndex','Frequency_Hz','SearchCenter_mps','WindowRelative','ScanPoints', ...
    'StrictMinimumCount','SelectedOnlyType','RefineAllType','SelectedOnlyCandidateCount', ...
    'RefineAllCandidateCount','SelectedOnlyCp_mps','RefineAllCp_mps','StrictDiscreteCp_mps', ...
    'StrictRefinedCp_mps','FallbackCp_mps','StrictDiscreteResidual','StrictRefinedResidual', ...
    'FallbackResidual','StrictDiscreteScore','StrictRefinedScore','FallbackScore', ...
    'FallbackDistanceToStrictDiscrete_mps','FallbackDistanceToStrictRefined_mps'});

disp(summary);

if writeCsv
    out = fullfile(repoRoot,'Results','mrlfe','diagnostics','valley_fallback_overlap');
    if ~isfolder(out), mkdir(out); end
    writetable(summary, fullfile(out,'valley_fallback_overlap_summary.csv'));
    fprintf('Saved Results/mrlfe/diagnostics/valley_fallback_overlap/valley_fallback_overlap_summary.csv\n');
end
end

function result = runPolicy(request, refineAll)
configuration = mrlfeResolveConfiguration(request);
configuration.internalOptions.trackerRefineCandidates = logical(refineAll);
problem = mrlfeBuildProblem(configuration);
raw = mrlfeSolveBranch(problem, configuration);
result = mrlfeBuildResult(configuration, raw, 0);
end

function request = buildRequest()
request = struct();
request.branch = "A0Like";
request.frequency_Hz = linspace(1000,12000,20).';
request.material = struct('mu_Pa',50e3,'etaS_Pas',0.10,'rho_kgm3',1000,'nu',0.4999);
request.geometry = struct('thickness_m',0.5e-3);
request.fluid = struct('density_kgm3',1000,'soundSpeed_mps',1500);
request.numerics = struct('preset',"fast");
request.selection = struct('strategy',"adaptive");
request.termination = struct('policy',"physicalTail");
request.fallback = struct('policy',"none");
end

function r = computeResidual(cp, omega, material, geometry, params)
r = nan(size(cp));
for i = 1:numel(cp)
    r(i) = mrlfeResidual(omega/cp(i), omega, material, geometry, params);
end
end

function idx = findLocalMinima(r, edgeGuard)
idx = [];
first = 1 + edgeGuard;
last = numel(r) - edgeGuard;
for i = max(2,first):min(numel(r)-1,last)
    if isfinite(r(i)) && r(i) < r(i-1) && r(i) < r(i+1)
        idx(end+1,1) = i; %#ok<AGROW>
    end
end
end

function score = normalScore(cp, residual, center, tracker)
pred = abs(cp-center)./max(abs(center),eps);
score = tracker.residualWeight .* log10(max(residual,tracker.residualFloor)) + ...
    tracker.predictionWeight .* pred.^2;
end

function root = findRepositoryRoot(anchor)
folder = fileparts(anchor);
while true
    if isfile(fullfile(folder,'startup.m')), root = folder; return; end
    parent = fileparts(folder);
    if strcmp(parent,folder), error('mrlfe:RepositoryRootNotFound','Repository root not found.'); end
    folder = parent;
end
end

function restoreSession(folder0,path0)
path(path0);
cd(folder0);
end
