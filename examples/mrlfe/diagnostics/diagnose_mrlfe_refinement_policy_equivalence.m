% TEMPORARY_DIAGNOSTIC
function summary = diagnose_mrlfe_refinement_policy_equivalence(varargin)
% Compare selected-only and refine-all after valley-fallback overlap fix.

p = inputParser;
p.addParameter('Repeats', 1, @(x)isnumeric(x) && isscalar(x) && x >= 1);
p.addParameter('WriteCsv', true, @(x)islogical(x) && isscalar(x));
p.parse(varargin{:});
opt = p.Results;

repoRoot = findRepositoryRoot(mfilename('fullpath'));
cd(repoRoot);
startup;

muValues = [50e3 75e3 158e3 250e3];
etaSValues = [0 0.05 0.10];
branches = ["A0Like" "S0Like"];
rows = [];
caseIndex = 0;

for branch = branches
    for etaS = etaSValues
        for mu = muValues
            caseIndex = caseIndex + 1;
            request = buildRequest(branch, etaS, mu);
            selected = runCase(request, false, opt.Repeats);
            refineAll = runCase(request, true, opt.Repeats);

            finite = isfinite(selected.result.phaseVelocity_mps) & isfinite(refineAll.result.phaseVelocity_mps);
            delta = abs(selected.result.phaseVelocity_mps(finite) - refineAll.result.phaseVelocity_mps(finite));
            maxAbs = max(delta, [], 'omitnan');
            if isempty(delta), maxAbs = NaN; end
            maxRel = max(delta ./ max(abs(refineAll.result.phaseVelocity_mps(finite)), eps), [], 'omitnan');
            if isempty(delta), maxRel = NaN; end

            row = table(caseIndex, branch, mu, etaS, selected.seconds, refineAll.seconds, ...
                maxAbs, maxRel, nnz(selected.result.validMask ~= refineAll.result.validMask), ...
                'VariableNames', {'CaseIndex','Branch','Mu_Pa','EtaS_Pas', ...
                'SelectedOnlySeconds','RefineAllSeconds','MaxAbsCpDifference_mps', ...
                'MaxRelativeCpDifference','ValidMaskMismatchCount'});
            rows = [rows; row]; %#ok<AGROW>
        end
    end
end

summary = rows;
disp(summary);
fprintf('\nMax |Delta Cp|: %.12g m/s\n', max(summary.MaxAbsCpDifference_mps, [], 'omitnan'));
fprintf('Max relative Delta Cp: %.12g\n', max(summary.MaxRelativeCpDifference, [], 'omitnan'));
fprintf('Total valid-mask mismatches: %d\n', sum(summary.ValidMaskMismatchCount));
fprintf('Median selected/refine-all runtime ratio: %.4f\n', ...
    median(summary.SelectedOnlySeconds ./ summary.RefineAllSeconds, 'omitnan'));

if opt.WriteCsv
    outputFolder = fullfile(repoRoot, 'Results', 'mrlfe', 'diagnostics', 'refinement_policy_equivalence');
    if ~isfolder(outputFolder), mkdir(outputFolder); end
    writetable(summary, fullfile(outputFolder, 'refinement_policy_equivalence_summary.csv'));
end
end

function out = runCase(request, refineAll, repeats)
configuration = mrlfeResolveConfiguration(request);
configuration.internalOptions.trackerRefineCandidates = logical(refineAll);
problem = mrlfeBuildProblem(configuration);
mrlfeSolveBranch(problem, configuration); % warm-up

t = nan(repeats,1);
for i = 1:repeats
    configuration = mrlfeResolveConfiguration(request);
    configuration.internalOptions.trackerRefineCandidates = logical(refineAll);
    problem = mrlfeBuildProblem(configuration);
    timer = tic;
    raw = mrlfeSolveBranch(problem, configuration);
    t(i) = toc(timer);
    result = mrlfeBuildResult(configuration, raw, t(i));
end
out = struct('result', result, 'seconds', median(t));
end

function request = buildRequest(branch, etaS, mu)
request = struct();
request.branch = branch;
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

function root = findRepositoryRoot(anchor)
root = fileparts(anchor);
while ~isfile(fullfile(root, 'startup.m'))
    parent = fileparts(root);
    if strcmp(parent, root), error('Repository root not found.'); end
    root = parent;
end
end
