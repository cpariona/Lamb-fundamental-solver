% TEMPORARY_DIAGNOSTIC
function [summary, candidates] = diagnose_mrlfe_candidate_ranking_corner(varargin)
%DIAGNOSE_MRLFE_CANDIDATE_RANKING_CORNER Inspect the one divergent Fast case.
%
% Case: A0Like, mu=50 kPa, etaS=0.10 Pa*s. The diagnostic finds the first
% solve-grid point where selected-only and refine-all differ, reconstructs the
% exact local Cp scan, and compares discrete versus continuously refined
% candidate scores. Production code is not modified.

parser = inputParser;
parser.addParameter('WriteCsv', true, @(x)islogical(x) && isscalar(x));
parser.parse(varargin{:});
opt = parser.Results;

repoRoot = findRepositoryRoot(mfilename('fullpath'));
originalFolder = pwd;
originalPath = path;
cleanup = onCleanup(@() restoreSession(originalFolder, originalPath)); %#ok<NASGU>
cd(repoRoot);
startup;

request = buildRequest();
[selected, configuration, problem] = runPolicy(request, false);
[refineAll, ~, ~] = runPolicy(request, true);

branchSelected = selected.debug.solverResult.branchSolve;
branchRefineAll = refineAll.debug.solverResult.branchSolve;
frequency = branchSelected.frequency(:);

if ~isequal(frequency, branchRefineAll.frequency(:))
    error('mrlfe:DiagnosticGridMismatch', 'Compared branches must use the same solve grid.');
end

validBoth = branchSelected.validCp(:) & branchRefineAll.validCp(:) & ...
    isfinite(branchSelected.Cp(:)) & isfinite(branchRefineAll.Cp(:));
delta = abs(branchSelected.Cp(:) - branchRefineAll.Cp(:));
firstIndex = find(validBoth & delta > 1e-10, 1, 'first');
if isempty(firstIndex)
    error('mrlfe:DiagnosticNoDivergence', 'No selected-only/refine-all divergence was found.');
end

centerSelected = branchSelected.adaptiveCenterCp(firstIndex);
centerRefineAll = branchRefineAll.adaptiveCenterCp(firstIndex);
windowSelected = branchSelected.adaptiveWindowUsed(firstIndex);
windowRefineAll = branchRefineAll.adaptiveWindowUsed(firstIndex);
tracker = branchSelected.dpOptions;

if abs(centerSelected - centerRefineAll) > 1e-10 || abs(windowSelected - windowRefineAll) > 1e-12
    error('mrlfe:DiagnosticPreDivergenceMismatch', ...
        'The first divergent point does not share the same search center/window.');
end

cpMin = max(tracker.cpMinFloor, centerSelected * (1 - windowSelected));
cpMax = min(tracker.cpMaxCeiling, centerSelected * (1 + windowSelected));
cpScan = linspace(cpMin, cpMax, tracker.cpScanPoints);

mrlfeParams = configuration.internalOptions.mrlfeParams;
mrlfeParams.etaS = request.material.etaS_Pas;
mrlfeParams.solveComplexK = false;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
omega = 2*pi*frequency(firstIndex);
residual = computeResidual(cpScan, omega, problem.material, problem.geometry, mrlfeParams);
idx = findLocalMinima(residual, tracker.edgeGuardPoints);
if isempty(idx)
    error('mrlfe:DiagnosticNoCandidate', 'No local candidate minimum found at the divergent point.');
end

[~, order] = sort(residual(idx), 'ascend');
idx = idx(order);
cpDiscrete = cpScan(idx(:));
residualDiscrete = residual(idx(:));
scoreDiscrete = candidateScore(cpDiscrete, residualDiscrete, centerSelected, tracker);
[~, discreteWinner] = min(scoreDiscrete);

[cpRefined, residualRefined] = refineCandidates(cpScan, idx, omega, ...
    problem.material, problem.geometry, mrlfeParams, tracker);
scoreRefined = candidateScore(cpRefined, residualRefined, centerSelected, tracker);
[~, refinedWinner] = min(scoreRefined);

candidateNumber = (1:numel(idx)).';
scanIndex = idx(:);
isDiscreteWinner = candidateNumber == discreteWinner;
isRefinedWinner = candidateNumber == refinedWinner;
candidates = table(candidateNumber, scanIndex, cpDiscrete(:), residualDiscrete(:), ...
    scoreDiscrete(:), cpRefined(:), residualRefined(:), scoreRefined(:), ...
    isDiscreteWinner, isRefinedWinner, ...
    'VariableNames', {'Candidate','ScanIndex','CpDiscrete_mps','ResidualDiscrete', ...
    'ScoreDiscrete','CpRefined_mps','ResidualRefined','ScoreRefined', ...
    'IsDiscreteWinner','IsRefinedWinner'});

summary = table( ...
    firstIndex, frequency(firstIndex), centerSelected, windowSelected, tracker.cpScanPoints, ...
    numel(idx), discreteWinner, refinedWinner, ...
    branchSelected.Cp(firstIndex), branchRefineAll.Cp(firstIndex), ...
    cpRefined(discreteWinner), cpRefined(refinedWinner), ...
    branchSelected.residual(firstIndex), branchRefineAll.residual(firstIndex), ...
    delta(firstIndex), ...
    'VariableNames', {'SolveIndex','Frequency_Hz','SearchCenter_mps','WindowRelative', ...
    'ScanPoints','CandidateCount','DiscreteWinner','RefinedWinner', ...
    'SelectedOnlyCp_mps','RefineAllCp_mps','RefinedDiscreteWinnerCp_mps', ...
    'RefinedAllWinnerCp_mps','SelectedOnlyResidual','RefineAllResidual','DeltaCp_mps'});

disp(summary);
disp(candidates);
fprintf('\nInterpretation:\n');
if discreteWinner ~= refinedWinner
    fprintf('- Refinement changes the winning candidate at the first divergent frequency.\n');
    fprintf('- Global selected-only replacement is therefore not equivalent to refine-all in this corner.\n');
else
    fprintf('- Candidate identity is unchanged; divergence must arise later in continuation.\n');
end

if opt.WriteCsv
    outputFolder = fullfile(repoRoot, 'Results', 'mrlfe', 'diagnostics', 'candidate_ranking_corner');
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    writetable(summary, fullfile(outputFolder, 'candidate_ranking_corner_summary.csv'));
    writetable(candidates, fullfile(outputFolder, 'candidate_ranking_corner_candidates.csv'));
    fprintf('Saved diagnostic output under Results/mrlfe/diagnostics/candidate_ranking_corner\n');
end
end

function [result, configuration, problem] = runPolicy(request, refineAll)
configuration = mrlfeResolveConfiguration(request);
configuration.internalOptions.trackerRefineCandidates = logical(refineAll);
problem = mrlfeBuildProblem(configuration);
raw = mrlfeSolveBranch(problem, configuration);
result = mrlfeBuildResult(configuration, raw, 0);
end

function request = buildRequest()
request = struct();
request.branch = "A0Like";
request.frequency_Hz = linspace(1000, 12000, 20).';
request.material = struct('mu_Pa', 50e3, 'etaS_Pas', 0.10, 'rho_kgm3', 1000, 'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', "fast");
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', "physicalTail");
request.fallback = struct('policy', "none");
end

function residual = computeResidual(cpScan, omega, material, geometry, mrlfeParams)
residual = nan(size(cpScan));
for i = 1:numel(cpScan)
    cp = cpScan(i);
    residual(i) = mrlfeResidual(omega / cp, omega, material, geometry, mrlfeParams);
end
end

function idx = findLocalMinima(residual, edgeGuardPoints)
idx = [];
firstAllowed = 1 + edgeGuardPoints;
lastAllowed = numel(residual) - edgeGuardPoints;
for i = max(2, firstAllowed):min(numel(residual)-1, lastAllowed)
    if isfinite(residual(i)) && residual(i) < residual(i-1) && residual(i) < residual(i+1)
        idx(end+1,1) = i; %#ok<AGROW>
    end
end
end

function score = candidateScore(cp, residual, center, tracker)
predTerm = abs(cp(:) - center) ./ max(abs(center), eps);
resTerm = log10(max(residual(:), tracker.residualFloor));
score = tracker.residualWeight .* resTerm + tracker.predictionWeight .* predTerm.^2;
end

function [cpRefined, residualRefined] = refineCandidates(cpScan, idx, omega, material, geometry, mrlfeParams, tracker)
cpRefined = cpScan(idx(:));
residualRefined = nan(size(cpRefined));
opt = optimset('Display', 'off', 'TolX', tracker.refineTolX, ...
    'MaxIter', tracker.refineMaxIter, 'MaxFunEvals', tracker.refineMaxFunEvals);
objective = @(cp) mrlfeResidual(omega / cp, omega, material, geometry, mrlfeParams);
for n = 1:numel(idx)
    i = idx(n);
    lower = cpScan(max(i-1,1));
    upper = cpScan(min(i+1,numel(cpScan)));
    [cpRefined(n), residualRefined(n)] = fminbnd(objective, lower, upper, opt);
end
end

function root = findRepositoryRoot(anchorFile)
folder = fileparts(anchorFile);
while true
    if isfile(fullfile(folder, 'startup.m'))
        root = folder;
        return
    end
    parent = fileparts(folder);
    if strcmp(parent, folder)
        error('mrlfe:RepositoryRootNotFound', 'Could not locate repository root.');
    end
    folder = parent;
end
end

function restoreSession(originalFolder, originalPath)
path(originalPath);
cd(originalFolder);
end
