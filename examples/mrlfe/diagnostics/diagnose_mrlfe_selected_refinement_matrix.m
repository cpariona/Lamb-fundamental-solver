function summary = diagnose_mrlfe_selected_refinement_matrix(varargin)
%DIAGNOSE_MRLFE_SELECTED_REFINEMENT_MATRIX Compare selected-only vs refine-all.
%
% Diagnostic-only characterization across the maintained Fast mRLFE matrix.
% Physics, grids, tracking, termination, and fallback remain fixed. Only the
% candidate-refinement policy changes.

parser = inputParser;
parser.addParameter('Repeats', 1, @(x)isnumeric(x) && isscalar(x) && x >= 1 && fix(x) == x);
parser.addParameter('WriteCsv', true, @(x)islogical(x) && isscalar(x));
parser.parse(varargin{:});
opt = parser.Results;

repoRoot = findRepositoryRoot(mfilename('fullpath'));
originalFolder = pwd;
originalPath = path;
cleanup = onCleanup(@() restoreSession(originalFolder, originalPath)); %#ok<NASGU>
cd(repoRoot);
startup;

muValues = [50e3 75e3 158e3 250e3];
etaSValues = [0 0.05 0.10];
branches = ["A0Like" "S0Like"];
rows = repmat(emptyRow(), 0, 1);

fprintf('\nmRLFE selected-refinement matrix diagnostic\n');
fprintf('===========================================\n');
fprintf('Fast matrix: 2 branches x 3 etaS x 4 mu = 24 cases\n\n');

caseIndex = 0;
for branch = branches
    for etaS = etaSValues
        for mu = muValues
            caseIndex = caseIndex + 1;
            request = buildRequest(branch, etaS, mu);
            selected = runCase(request, false, opt.Repeats);
            refineAll = runCase(request, true, opt.Repeats);

            comparison = compareResults(selected.result, refineAll.result);
            row = emptyRow();
            row.CaseIndex = caseIndex;
            row.Branch = branch;
            row.Mu_Pa = mu;
            row.EtaS_Pas = etaS;
            row.SelectedOnlySeconds = selected.medianSeconds;
            row.RefineAllSeconds = refineAll.medianSeconds;
            row.RuntimeRatioSelectedVsAll = selected.medianSeconds / refineAll.medianSeconds;
            row.MaxAbsCpDifference_mps = comparison.maxAbsCpDifference_mps;
            row.MaxRelativeCpDifference = comparison.maxRelativeCpDifference;
            row.ValidMaskMismatchCount = comparison.validMaskMismatchCount;
            row.FiniteMaskMismatchCount = comparison.finiteMaskMismatchCount;
            row.SelectedOnlyValidFraction = nnz(selected.result.validMask) / numel(selected.result.validMask);
            row.RefineAllValidFraction = nnz(refineAll.result.validMask) / numel(refineAll.result.validMask);
            rows(end+1,1) = row; %#ok<AGROW>

            fprintf('%2d %-6s etaS=%5.2f mu=%7.0f | dCp=%9.3g | masks=%d | time %.3f/%.3f s\n', ...
                caseIndex, branch, etaS, mu, comparison.maxAbsCpDifference_mps, ...
                comparison.validMaskMismatchCount, selected.medianSeconds, refineAll.medianSeconds);
        end
    end
end

summary = struct2table(rows);

fprintf('\nMatrix summary\n');
fprintf('--------------\n');
fprintf('Max |Delta Cp|: %.12g m/s\n', max(summary.MaxAbsCpDifference_mps));
fprintf('Max relative Delta Cp: %.12g\n', max(summary.MaxRelativeCpDifference));
fprintf('Total valid-mask mismatches: %d\n', sum(summary.ValidMaskMismatchCount));
fprintf('Total finite-mask mismatches: %d\n', sum(summary.FiniteMaskMismatchCount));
fprintf('Median selected/refine-all runtime ratio: %.4f\n', median(summary.RuntimeRatioSelectedVsAll));

if opt.WriteCsv
    outputFolder = fullfile(repoRoot, 'Results', 'mrlfe', 'diagnostics', 'selected_refinement_matrix');
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    writetable(summary, fullfile(outputFolder, 'selected_refinement_matrix_summary.csv'));
    fprintf('Saved diagnostic output under Results/mrlfe/diagnostics/selected_refinement_matrix\n');
end
end

function out = runCase(request, refineAll, repeats)
durations = nan(repeats,1);
result = struct();

% Warm-up.
configuration = mrlfeResolveConfiguration(request);
configuration.internalOptions.trackerRefineCandidates = logical(refineAll);
problem = mrlfeBuildProblem(configuration);
raw = mrlfeSolveBranch(problem, configuration);
mrlfeBuildResult(configuration, raw, 0); %#ok<VUNUS>

for r = 1:repeats
    configuration = mrlfeResolveConfiguration(request);
    configuration.internalOptions.trackerRefineCandidates = logical(refineAll);
    problem = mrlfeBuildProblem(configuration);
    timer = tic;
    raw = mrlfeSolveBranch(problem, configuration);
    elapsed = toc(timer);
    result = mrlfeBuildResult(configuration, raw, elapsed);
    durations(r) = elapsed;
end

out = struct('result', result, 'medianSeconds', median(durations));
end

function request = buildRequest(branch, etaS, mu)
request = struct();
request.branch = string(branch);
request.frequency_Hz = linspace(1000, 12000, 20).';
request.material = struct('mu_Pa', mu, 'etaS_Pas', etaS, 'rho_kgm3', 1000, 'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', "fast");
request.selection = struct('strategy', "adaptive");
if branch == "A0Like"
    request.termination = struct('policy', "physicalTail");
else
    request.termination = struct('policy', "none");
end
request.fallback = struct('policy', "none");
end

function comparison = compareResults(a, b)
finiteA = isfinite(a.phaseVelocity_mps);
finiteB = isfinite(b.phaseVelocity_mps);
finite = finiteA & finiteB;
if any(finite)
    delta = abs(a.phaseVelocity_mps(finite) - b.phaseVelocity_mps(finite));
    comparison.maxAbsCpDifference_mps = max(delta);
    comparison.maxRelativeCpDifference = max(delta ./ max(abs(b.phaseVelocity_mps(finite)), eps));
else
    comparison.maxAbsCpDifference_mps = NaN;
    comparison.maxRelativeCpDifference = NaN;
end
comparison.validMaskMismatchCount = nnz(a.validMask ~= b.validMask);
comparison.finiteMaskMismatchCount = nnz(finiteA ~= finiteB);
end

function row = emptyRow()
row = struct( ...
    'CaseIndex', 0, ...
    'Branch', "", ...
    'Mu_Pa', NaN, ...
    'EtaS_Pas', NaN, ...
    'SelectedOnlySeconds', NaN, ...
    'RefineAllSeconds', NaN, ...
    'RuntimeRatioSelectedVsAll', NaN, ...
    'MaxAbsCpDifference_mps', NaN, ...
    'MaxRelativeCpDifference', NaN, ...
    'ValidMaskMismatchCount', 0, ...
    'FiniteMaskMismatchCount', 0, ...
    'SelectedOnlyValidFraction', NaN, ...
    'RefineAllValidFraction', NaN);
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
