% TEMPORARY_DIAGNOSTIC
function summary = diagnoseMrlfeAdaptiveScanMatrix(varargin)
%DIAGNOSEMRLFEADAPTIVESCANMATRIX Compare adaptive 100->260 scan against fixed 260.

parser = inputParser;
parser.addParameter('Repeats', 1, @(x)isnumeric(x) && isscalar(x) && x >= 1 && fix(x) == x);
parser.addParameter('WriteCsv', true, @(x)islogical(x) && isscalar(x));
parser.parse(varargin{:});
opt = parser.Results;

muValues = [50e3 75e3 158e3 250e3];
etaSValues = [0 0.05 0.10];
branches = ["A0Like" "S0Like"];
rows = repmat(emptyRow(), 0, 1);

fprintf('\nmRLFE adaptive Cp-scan matrix\n');
fprintf('==============================\n');
fprintf('Adaptive policy: 100-point coarse scan, 260-point rescue on fallback/miss.\n');
fprintf('Reference: fixed 260-point scan.\n\n');

caseIndex = 0;
for branch = branches
    for etaS = etaSValues
        for mu = muValues
            caseIndex = caseIndex + 1;
            request = buildRequest(branch, etaS, mu);
            adaptive = runCase(request, 100, 260, opt.Repeats);
            reference = runCase(request, 260, 260, opt.Repeats);
            cmp = compareRuns(adaptive, reference);

            row = emptyRow();
            row.CaseIndex = caseIndex;
            row.Branch = branch;
            row.Mu_Pa = mu;
            row.EtaS_Pas = etaS;
            row.AdaptiveSeconds = adaptive.medianSeconds;
            row.Fixed260Seconds = reference.medianSeconds;
            row.SpeedupVs260 = reference.medianSeconds / adaptive.medianSeconds;
            row.MaxAbsCpDiff_mps = cmp.maxAbsCp;
            row.MaxRelativeCpDiff = cmp.maxRelCp;
            row.ValidMaskMismatchCount = cmp.validMaskMismatch;
            row.FiniteMaskMismatchCount = cmp.finiteMaskMismatch;
            row.CandidateTypeMismatchCount = cmp.candidateTypeMismatch;
            row.RescueScanCount = nnz(adaptive.branch.adaptiveRescueScanUsed);
            row.RescueScanFraction = row.RescueScanCount / numel(adaptive.branch.frequency);
            row.AdaptiveValidFraction = nnz(adaptive.branch.validCp) / numel(adaptive.branch.validCp);
            row.ReferenceValidFraction = nnz(reference.branch.validCp) / numel(reference.branch.validCp);
            rows(end+1,1) = row; %#ok<AGROW>

            fprintf('%2d %-6s etaS=%4.2f mu=%7.0f | %.2fx | dCp %.3g | masks %d | types %d | rescue %d\n', ...
                caseIndex, branch, etaS, mu, row.SpeedupVs260, row.MaxAbsCpDiff_mps, ...
                row.ValidMaskMismatchCount, row.CandidateTypeMismatchCount, row.RescueScanCount);
        end
    end
end

summary = struct2table(rows);

fprintf('\nAggregate\n');
fprintf('---------\n');
fprintf('Median speedup: %.3fx\n', median(summary.SpeedupVs260));
fprintf('Minimum speedup: %.3fx\n', min(summary.SpeedupVs260));
fprintf('Max |Delta Cp|: %.12g m/s\n', max(summary.MaxAbsCpDiff_mps));
fprintf('Max relative Delta Cp: %.12g\n', max(summary.MaxRelativeCpDiff));
fprintf('Total valid-mask mismatches: %d\n', sum(summary.ValidMaskMismatchCount));
fprintf('Total finite-mask mismatches: %d\n', sum(summary.FiniteMaskMismatchCount));
fprintf('Total candidate-type mismatches: %d\n', sum(summary.CandidateTypeMismatchCount));
fprintf('Total rescue scans: %d\n', sum(summary.RescueScanCount));

if opt.WriteCsv
    repoRoot = findRepositoryRoot(mfilename('fullpath'));
    outputFolder = fullfile(repoRoot, 'Results', 'mrlfe', 'diagnostics', 'adaptive_scan_matrix');
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    writetable(summary, fullfile(outputFolder, 'mrlfe_adaptive_scan_matrix.csv'));
    fprintf('Saved Results/mrlfe/diagnostics/adaptive_scan_matrix/mrlfe_adaptive_scan_matrix.csv\n');
end
end

function out = runCase(request, coarsePoints, rescuePoints, repeats)
configuration = mrlfeResolveConfiguration(request);
configuration.internalOptions.trackerCpScanPoints = coarsePoints;
configuration.internalOptions.trackerRescueCpScanPoints = rescuePoints;
problem = mrlfeBuildProblem(configuration);

raw = mrlfeSolveBranch(problem, configuration); %#ok<NASGU>
times = nan(repeats,1);
for r = 1:repeats
    t = tic;
    raw = mrlfeSolveBranch(problem, configuration);
    times(r) = toc(t);
end
out = struct('raw', raw, 'branch', raw.branchSolve, 'medianSeconds', median(times));
end

function cmp = compareRuns(a, b)
cpA = a.branch.Cp(:);
cpB = b.branch.Cp(:);
finiteA = isfinite(cpA);
finiteB = isfinite(cpB);
finite = finiteA & finiteB;
if any(finite)
    delta = abs(cpA(finite) - cpB(finite));
    cmp.maxAbsCp = max(delta);
    cmp.maxRelCp = max(delta ./ max(abs(cpB(finite)), eps));
else
    cmp.maxAbsCp = NaN;
    cmp.maxRelCp = NaN;
end
cmp.validMaskMismatch = nnz(logical(a.branch.validCp(:)) ~= logical(b.branch.validCp(:)));
cmp.finiteMaskMismatch = nnz(finiteA ~= finiteB);
cmp.candidateTypeMismatch = nnz(string(a.branch.candidateType(:)) ~= string(b.branch.candidateType(:)));
end

function request = buildRequest(branch, etaS, mu)
defaults = mrlfeDefaultParameters();
publicOptions = mrlfeDefaultOptions();
request = struct();
request.branch = string(branch);
request.frequency_Hz = linspace(1000, 12000, 20).';
request.material = struct('mu_Pa', mu, 'etaS_Pas', etaS, ...
    'rho_kgm3', defaults.rho_kgm3, 'nu', defaults.nu);
request.geometry = struct('thickness_m', defaults.thickness_m);
request.fluid = struct('density_kgm3', defaults.fluidDensity_kgm3, ...
    'soundSpeed_mps', defaults.fluidSoundSpeed_mps);
request.numerics = struct('preset', "fast");
request.selection = publicOptions.selection;
if branch == "A0Like"
    request.termination = struct('policy', publicOptions.termination.A0Like);
else
    request.termination = struct('policy', publicOptions.termination.S0Like);
end
request.fallback = publicOptions.fallback;
end

function row = emptyRow()
row = struct( ...
    'CaseIndex',0, 'Branch',"", 'Mu_Pa',NaN, 'EtaS_Pas',NaN, ...
    'AdaptiveSeconds',NaN, 'Fixed260Seconds',NaN, 'SpeedupVs260',NaN, ...
    'MaxAbsCpDiff_mps',NaN, 'MaxRelativeCpDiff',NaN, ...
    'ValidMaskMismatchCount',0, 'FiniteMaskMismatchCount',0, ...
    'CandidateTypeMismatchCount',0, 'RescueScanCount',0, 'RescueScanFraction',NaN, ...
    'AdaptiveValidFraction',NaN, 'ReferenceValidFraction',NaN);
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