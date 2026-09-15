function test_mrlfe_robust_start_contract()
%TEST_MRLFE_ROBUST_START_CONTRACT Verify forward-only A0Like recovery.

solveFrequency_Hz = unique([10; (184:150:4000).'; 4000]);
requestedFrequency_Hz = [10 184 500 1000 2000 4000].';

request = struct();
request.branch = "A0Like";
request.frequency_Hz = requestedFrequency_Hz;
request.material = struct( ...
    'mu_Pa', 75e3, ...
    'etaS_Pas', 0, ...
    'rho_kgm3', 1070, ...
    'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct( ...
    'preset', "fast", ...
    'frequencySolveOverride_Hz', solveFrequency_Hz);
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', "physicalTail");
request.fallback = struct('policy', "none");

result = lamb.models.mrlfe.mrlfeSolve(request);
branch = result.debug.solverResult.branchSolve;

% Correct RL seeds now establish a valid run without recovery on this grid.
% Independent 90-digit determinant roots verify the newly covered prefix.
assert(~branch.robustStart.Attempted && branch.robustStart.Reason == "not_required");
assert(abs(branch.Cp(1) - 0.23213780739155229924466968812736377) < 1e-7);
assert(abs(branch.Cp(3) - 1.73706538911752548214230665103858257) < 1e-7);
assert(~branch.validCp(2) && ~branch.validCp(4), ...
    'Unestablished points must remain invalid even when the prefix gains coverage.');

% Exercise recovery with an explicitly failed seed rather than depending on
% the retired RL prediction fallback to accidentally supply a constant seed.
configuration = lamb.models.mrlfe.configuration.mrlfeResolveConfiguration(request);
problem = lamb.models.mrlfe.core.mrlfeBuildProblem(configuration);
failedSeed = lamb.models.mrlfe.tracking.mrlfeBuildSeed(problem, configuration);
failedSeed.Cp(:) = NaN;
failedSeed.k(:) = NaN;
failedSeed.valid(:) = false;
options = configuration.internalOptions;
mp = options.mrlfeParams;
mp.etaS = 0;
mp.etaL = 0;
mp.useComplexLambda = false;
mp.solveComplexK = false;
branch = lamb.models.mrlfe.tracking.mrlfeTrackBranchRobustStart( ...
    problem, failedSeed, configuration, mp, options);

assert(isfield(branch, 'robustStart') && isstruct(branch.robustStart), ...
    'A0Like branch diagnostics must include robustStart metadata.');
assert(branch.robustStart.Enabled, ...
    'Robust-start must be enabled for A0Like production solving.');
assert(branch.robustStart.Attempted, ...
    'The controlled failed seed must attempt robust-start recovery.');

if ~branch.robustStart.Applied
    fprintf('\nRobust-start candidate diagnostics\n');
    fprintf('----------------------------------\n');
    fprintf('Base valid points: %d/%d\n', nnz(branch.validCp), numel(branch.validCp));
    fprintf('Policy reason: %s\n', string(branch.robustStart.Reason));
    fprintf('Probes attempted: %d\n', branch.robustStart.ProbesAttempted);

    candidateFrequencies_Hz = branch.robustStart.CandidateFrequencies_Hz(:);
    for i = 1:numel(candidateFrequencies_Hz)
        idx = find(solveFrequency_Hz >= candidateFrequencies_Hz(i), 1, 'first');
        if isempty(idx) || numel(solveFrequency_Hz) - idx + 1 < branch.robustStart.MinValidRun
            continue;
        end

        probeRequest = request;
        probeFrequency_Hz = solveFrequency_Hz(idx:end);
        probeRequest.frequency_Hz = probeFrequency_Hz;
        probeRequest.numerics.frequencySolveOverride_Hz = probeFrequency_Hz;
        probeRequest.termination.policy = "none";

        probeResult = lamb.models.mrlfe.mrlfeSolve(probeRequest);
        probeBranch = probeResult.debug.solverResult.branchSolve;
        initialRun = countInitialValidRun(probeBranch.validCp);
        firstValid = find(probeBranch.validCp, 1, 'first');
        lastValid = find(probeBranch.validCp, 1, 'last');

        if isempty(firstValid)
            firstValidFrequency_Hz = NaN;
            lastValidFrequency_Hz = NaN;
        else
            firstValidFrequency_Hz = probeBranch.frequency(firstValid);
            lastValidFrequency_Hz = probeBranch.frequency(lastValid);
        end

        fprintf(['Candidate %.0f Hz -> grid start %.0f Hz | initial run %d | ' ...
            'valid %d/%d | first %.0f Hz | last %.0f Hz | robust applied %d\n'], ...
            candidateFrequencies_Hz(i), probeFrequency_Hz(1), initialRun, ...
            nnz(probeBranch.validCp), numel(probeBranch.validCp), ...
            firstValidFrequency_Hz, lastValidFrequency_Hz, ...
            probeBranch.robustStart.Applied);
    end

    error('mrlfe:RobustStartNotApplied', ...
        ['The low-frequency regression case did not apply a stable robust start. ' ...
        'Use the candidate diagnostics printed above to identify the failing interval.']);
end

assert(isfinite(branch.robustStart.StartIndex) && branch.robustStart.StartIndex > 1, ...
    'Robust-start must begin after the failing low-frequency prefix.');
assert(isfinite(branch.robustStart.StartFrequency_Hz), ...
    'Robust-start metadata must report the selected start frequency.');
assert(all(~branch.validCp(1:branch.robustStart.StartIndex-1)), ...
    'Frequencies before the robust start must remain invalid without backward tracking.');
assert(nnz(branch.validCp(branch.robustStart.StartIndex:end)) >= branch.robustStart.MinValidRun, ...
    'The recovered forward branch must contain the required stable valid run.');
assert(isequal(result.frequency_Hz(:), requestedFrequency_Hz), ...
    'Robust-start must not change the public requested frequency grid.');
assert(~result.fallback.applied, ...
    'Robust-start is a tracking policy and must not be reported as solver fallback.');

fprintf(['test_mrlfe_robust_start_contract passed. A0Like recovers forward from a ' ...
    'stable start while preserving invalid lower frequencies.\n']);
end

function runLength = countInitialValidRun(validMask)
validMask = logical(validMask(:));
runLength = 0;
for i = 1:numel(validMask)
    if ~validMask(i)
        break;
    end
    runLength = runLength + 1;
end
end
