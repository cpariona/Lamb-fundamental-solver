function branch = mrlfeTrackBranchRobustStart(problem, seedMode, configuration, mrlfeParams, options)
%MRLFETRACKBRANCHROBUSTSTART Recover A0Like tracking from a stable start.
%
% The maintained adaptive tracker is attempted first. If A0Like does not
% establish the required valid run, short forward probes are evaluated from
% configured candidate frequencies. Each probe rebuilds a complete model-layer
% subproblem on the candidate interval so that Rayleigh-Lamb continuation and
% seed construction are independent of the failed low-frequency prefix. The
% first successful candidate is then tracked forward to the end of the solve
% grid. Frequencies before the robust start remain invalid. No backward tracking
% is performed.

baseBranch = mrlfeTrackBranchAdaptive(problem, seedMode, configuration, mrlfeParams, options);
policy = resolvePolicy(configuration, options);

if ~policy.enabled || hasValidRun(baseBranch.validCp, policy.minValidRun)
    branch = attachMetadata(baseBranch, policy, false, false, NaN, NaN, 0, "not_required");
    return;
end

frequency = seedMode.frequency(:);
candidateIndices = resolveCandidateIndices(frequency, policy.candidateFrequencies_Hz, policy.maxCandidates);
selectedIndex = NaN;
probesAttempted = 0;

for i = 1:numel(candidateIndices)
    startIndex = candidateIndices(i);
    stopIndex = min(numel(frequency), startIndex + policy.minValidRun - 1);
    if stopIndex - startIndex + 1 < policy.minValidRun
        continue;
    end

    probesAttempted = probesAttempted + 1;
    probeProblem = rebuildSubproblem(configuration, frequency(startIndex:stopIndex));
    probeSeed = mrlfeBuildSeed(probeProblem, configuration);
    probeBranch = mrlfeTrackBranchAdaptive(probeProblem, probeSeed, configuration, mrlfeParams, options);
    if hasInitialValidRun(probeBranch.validCp, policy.minValidRun)
        selectedIndex = startIndex;
        break;
    end
end

if ~isfinite(selectedIndex)
    branch = attachMetadata(baseBranch, policy, true, false, NaN, NaN, probesAttempted, "no_stable_candidate");
    return;
end

forwardProblem = rebuildSubproblem(configuration, frequency(selectedIndex:end));
forwardSeed = mrlfeBuildSeed(forwardProblem, configuration);
forwardBranch = mrlfeTrackBranchAdaptive(forwardProblem, forwardSeed, configuration, mrlfeParams, options);
branch = padForwardBranch(forwardBranch, seedMode, selectedIndex);
branch = attachMetadata(branch, policy, true, true, selectedIndex, frequency(selectedIndex), probesAttempted, "stable_candidate_found");
branch.note = "mRLFE branch tracked forward from a robust A0Like start; earlier frequencies remain invalid.";
end

function policy = resolvePolicy(configuration, options)
policy = struct();
policy.name = "robustStart";
policy.enabled = configuration.branch == "A0Like" && ...
    logical(getOption(options, 'mrlfeRobustStartEnabled', true));
policy.candidateFrequencies_Hz = getOption(options, 'mrlfeRobustStartCandidateFrequencies_Hz', ...
    [75 100 150 200 300 500 750 1000]);
policy.candidateFrequencies_Hz = unique(double(policy.candidateFrequencies_Hz(:)), 'stable');
policy.candidateFrequencies_Hz = policy.candidateFrequencies_Hz( ...
    isfinite(policy.candidateFrequencies_Hz) & policy.candidateFrequencies_Hz > 0);
policy.minValidRun = max(2, round(getOption(options, 'mrlfeRobustStartMinValidRun', ...
    getOption(options, 'mrlfeAdaptiveEstablishedMinValidRun', 8))));
policy.maxCandidates = max(1, round(getOption(options, 'mrlfeRobustStartMaxCandidates', 8)));
end

function indices = resolveCandidateIndices(frequency, candidateFrequencies_Hz, maxCandidates)
indices = [];
for i = 1:numel(candidateFrequencies_Hz)
    idx = find(frequency >= candidateFrequencies_Hz(i), 1, 'first');
    if ~isempty(idx)
        indices(end+1,1) = idx; %#ok<AGROW>
    end
end
indices = unique(indices, 'stable');
indices = indices(1:min(numel(indices), maxCandidates));
end

function tf = hasValidRun(validMask, requiredRun)
validMask = logical(validMask(:));
runLength = 0;
tf = false;
for i = 1:numel(validMask)
    if validMask(i)
        runLength = runLength + 1;
        if runLength >= requiredRun
            tf = true;
            return;
        end
    else
        runLength = 0;
    end
end
end

function tf = hasInitialValidRun(validMask, requiredRun)
validMask = logical(validMask(:));
tf = numel(validMask) >= requiredRun && all(validMask(1:requiredRun));
end

function problemOut = rebuildSubproblem(configurationIn, frequencySlice_Hz)
frequencySlice_Hz = frequencySlice_Hz(:);
configurationOut = configurationIn;
configurationOut.request.frequency_Hz = frequencySlice_Hz;
configurationOut.request.numerics.frequencySolveOverride_Hz = frequencySlice_Hz;
problemOut = mrlfeBuildProblem(configurationOut);
if isfield(problemOut, 'frequencyGrid') && isstruct(problemOut.frequencyGrid)
    problemOut.frequencyGrid.source = "robustStartRebuild";
end
end

function branch = padForwardBranch(forwardBranch, fullSeed, startIndex)
branch = forwardBranch;
numFull = numel(fullSeed.frequency);
numForward = numel(forwardBranch.frequency);
if numForward ~= numFull - startIndex + 1
    error('mrlfe:InvalidRobustStartResult', ...
        'Forward robust-start result length does not match the solve grid tail.');
end

branch.frequency = fullSeed.frequency(:);
branch.omega = fullSeed.omega(:);
branch.seedCp = fullSeed.Cp(:);
branch.seedK = branch.omega ./ branch.seedCp;

numericNaNFields = {'k','kReal','Cp','kThickness','residual','score', ...
    'candidateIndex','candidateRank','adaptiveWindowUsed','adaptiveCenterCp'};
for i = 1:numel(numericNaNFields)
    name = numericNaNFields{i};
    branch.(name) = prependNumeric(forwardBranch.(name), numFull, startIndex, NaN);
end

numericZeroFields = {'kImag','attenuation','adaptiveCandidateCount'};
for i = 1:numel(numericZeroFields)
    name = numericZeroFields{i};
    branch.(name) = prependNumeric(forwardBranch.(name), numFull, startIndex, 0);
end

logicalFields = {'validResidual','validReference','validSmooth','validCp','valid'};
for i = 1:numel(logicalFields)
    name = logicalFields{i};
    branch.(name) = prependLogical(forwardBranch.(name), numFull, startIndex);
end

candidateType = strings(numFull,1);
candidateType(:) = "none";
candidateType(startIndex:end) = string(forwardBranch.candidateType(:));
branch.candidateType = candidateType;

if isfield(branch, 'adaptiveCut') && isstruct(branch.adaptiveCut)
    localIndex = branch.adaptiveCut.FirstCutIndex;
    if isfinite(localIndex)
        fullIndex = startIndex + localIndex - 1;
        branch.adaptiveCut.FirstCutIndex = fullIndex;
        branch.adaptiveCut.FirstCutFrequency = branch.frequency(fullIndex);
    end
    branch.adaptiveCut.ValidPointsAfterCut = nnz(branch.validCp);
end
end

function out = prependNumeric(tail, numFull, startIndex, fillValue)
out = repmat(fillValue, numFull, 1);
out(startIndex:end) = tail(:);
end

function out = prependLogical(tail, numFull, startIndex)
out = false(numFull,1);
out(startIndex:end) = logical(tail(:));
end

function branch = attachMetadata(branch, policy, attempted, applied, startIndex, startFrequency, probesAttempted, reason)
branch.robustStart = struct( ...
    'PolicyName', policy.name, ...
    'Enabled', policy.enabled, ...
    'Attempted', logical(attempted), ...
    'Applied', logical(applied), ...
    'StartIndex', startIndex, ...
    'StartFrequency_Hz', startFrequency, ...
    'CandidateFrequencies_Hz', policy.candidateFrequencies_Hz(:), ...
    'MinValidRun', policy.minValidRun, ...
    'MaxCandidates', policy.maxCandidates, ...
    'ProbesAttempted', probesAttempted, ...
    'Reason', string(reason));
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end