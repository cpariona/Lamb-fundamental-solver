function mrlfeResults = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, options)
% Compute mRLFE fundamental-like branches.
%
% The model can use either Rayleigh-Lamb A0/S0 branches or previously
% computed mRLFE A0Like/S0Like branches as seeds. Branch computation can be
% restricted with options.mrlfeComputeA0Like and options.mrlfeComputeS0Like.

if nargin < 6
    options = struct();
end

requestedFrequency = frequency(:);
timerStart = tic;
solveComplexK = isfield(mrlfeParams, 'solveComplexK') && mrlfeParams.solveComplexK;
computeA0Like = getOption(options, 'mrlfeComputeA0Like', true);
computeS0Like = getOption(options, 'mrlfeComputeS0Like', true);

if getOption(options, 'mrlfeUseUnifiedAtlasRoute', false) && ~solveComplexK
    mrlfeResults = solveMRLFEAtlasUnified(requestedFrequency, material, geometry, seedModes, mrlfeParams, options);
    return;
end

useInternalTrackingGrid = getOption(options, 'mrlfeUseInternalTrackingGrid', false) && ~solveComplexK;
trackingFrequency = buildMRLFETrackingFrequency(requestedFrequency, options, useInternalTrackingGrid);

mrlfeResults = struct();
mrlfeResults.modelName = "mRLFE";
if solveComplexK
    mrlfeResults.variant = "complex-k";
    mrlfeResults.description = "Complex-k modified Rayleigh-Lamb fluid-loaded prototype.";
else
    mrlfeResults.variant = "real-k";
    mrlfeResults.description = "Real-k modified Rayleigh-Lamb fluid-loaded model.";
end
mrlfeResults.parameters = mrlfeParams;
mrlfeResults.requestedBranches = struct('A0Like', logical(computeA0Like), 'S0Like', logical(computeS0Like));
mrlfeResults.frequency = requestedFrequency;
mrlfeResults.tracking = struct();
mrlfeResults.tracking.usedInternalGrid = logical(useInternalTrackingGrid && numel(trackingFrequency) ~= numel(requestedFrequency));
mrlfeResults.tracking.requestedFrequency = requestedFrequency;
mrlfeResults.tracking.trackingFrequency = trackingFrequency;
mrlfeResults.branches = struct();

useA0DP = isfield(options, 'mrlfeA0UseDPTracker') && options.mrlfeA0UseDPTracker && ~solveComplexK;

if computeA0Like
    seedA0 = getSeedMode(seedModes, "A0");
    if ~isempty(seedA0)
        branchOptions = applyBranchSpecificOptions("A0Like", options);
        seedA0Tracking = resampleSeedMode(seedA0, trackingFrequency);
        if useA0DP
            preliminaryA0 = solveMRLFEBranch("A0Like", seedA0Tracking, material, geometry, mrlfeParams, branchOptions);
            trackedA0 = solveMRLFEBranchDP("A0Like", seedA0Tracking, material, geometry, mrlfeParams, branchOptions, preliminaryA0);
            trackedA0.preliminaryBranch = preliminaryA0;
        else
            trackedA0 = solveMRLFEBranch("A0Like", seedA0Tracking, material, geometry, mrlfeParams, branchOptions);
        end
        mrlfeResults.branches.A0Like = resampleMRLFEBranch(trackedA0, requestedFrequency, useInternalTrackingGrid);
    end
end

if computeS0Like
    seedS0 = getSeedMode(seedModes, "S0");
    if ~isempty(seedS0)
        branchOptions = applyBranchSpecificOptions("S0Like", options);
        seedS0Tracking = resampleSeedMode(seedS0, trackingFrequency);
        trackedS0 = solveMRLFEBranch("S0Like", seedS0Tracking, material, geometry, mrlfeParams, branchOptions);
        mrlfeResults.branches.S0Like = resampleMRLFEBranch(trackedS0, requestedFrequency, useInternalTrackingGrid);
    end
end

mrlfeResults.diagnostics = buildMRLFEDiagnostics(mrlfeResults, toc(timerStart));
end

function seedMode = getSeedMode(seedModes, familyName)
seedMode = [];
switch string(familyName)
    case "A0"
        if isfield(seedModes, 'A0Like')
            seedMode = seedModes.A0Like;
        elseif isfield(seedModes, 'A0')
            seedMode = seedModes.A0;
        end
    case "S0"
        if isfield(seedModes, 'S0Like')
            seedMode = seedModes.S0Like;
        elseif isfield(seedModes, 'S0')
            seedMode = seedModes.S0;
        end
end
end

function trackingFrequency = buildMRLFETrackingFrequency(requestedFrequency, options, useInternalTrackingGrid)
requestedFrequency = requestedFrequency(:);
if ~useInternalTrackingGrid || numel(requestedFrequency) < 2
    trackingFrequency = requestedFrequency;
    return;
end
factor = getOption(options, 'mrlfeInternalTrackingPointFactor', 2);
minPoints = getOption(options, 'mrlfeInternalTrackingMinPoints', 30);
maxPoints = getOption(options, 'mrlfeInternalTrackingMaxPoints', 400);
if ~isnumeric(factor) || ~isscalar(factor) || ~isfinite(factor) || factor < 1
    factor = 2;
end
if ~isnumeric(minPoints) || ~isscalar(minPoints) || ~isfinite(minPoints) || minPoints < 2
    minPoints = 30;
end
if ~isnumeric(maxPoints) || ~isscalar(maxPoints) || ~isfinite(maxPoints) || maxPoints < minPoints
    maxPoints = max(minPoints, numel(requestedFrequency));
end
nPoints = min(maxPoints, max([numel(requestedFrequency), ceil(factor * numel(requestedFrequency)), minPoints]));
fMin = min(requestedFrequency);
fMax = max(requestedFrequency);
trackingFrequency = unique([requestedFrequency; linspace(fMin, fMax, nPoints).'], 'sorted');
end

function seedOut = resampleSeedMode(seedIn, frequencyOut)
seedOut = seedIn;
frequencyOut = frequencyOut(:);
frequencyIn = seedIn.frequency(:);
seedOut.frequency = frequencyOut;
seedOut.omega = 2*pi*frequencyOut;
seedOut.k = interpolateNumericField(seedIn, 'k', frequencyIn, frequencyOut, false);
if isfield(seedIn, 'kReal')
    seedOut.kReal = interpolateNumericField(seedIn, 'kReal', frequencyIn, frequencyOut, false);
end
if isfield(seedIn, 'kImag')
    seedOut.kImag = interpolateNumericField(seedIn, 'kImag', frequencyIn, frequencyOut, false);
end
if isfield(seedIn, 'Cp')
    seedOut.Cp = interpolateNumericField(seedIn, 'Cp', frequencyIn, frequencyOut, false);
end
if isfield(seedIn, 'kThickness')
    seedOut.kThickness = interpolateNumericField(seedIn, 'kThickness', frequencyIn, frequencyOut, false);
end
if isfield(seedIn, 'valid')
    seedOut.valid = interpolateLogicalField(seedIn.valid, frequencyIn, frequencyOut);
end
end

function branchOut = resampleMRLFEBranch(branchIn, requestedFrequency, usedInternalGrid)
if ~usedInternalGrid
    branchOut = branchIn;
    branchOut.internalTracking = struct('used', false, 'trackingFrequency', branchIn.frequency(:));
    return;
end
requestedFrequency = requestedFrequency(:);
frequencyIn = branchIn.frequency(:);
branchOut = branchIn;
branchOut.internalTracking = struct();
branchOut.internalTracking.used = true;
branchOut.internalTracking.trackingFrequency = frequencyIn;
branchOut.internalTracking.trackingBranch = branchIn;
branchOut.frequency = requestedFrequency;
branchOut.omega = 2*pi*requestedFrequency;

numericFields = {'k', 'kReal', 'kImag', 'attenuation', 'Cp', 'kThickness', 'residual', 'score', 'seedK', 'seedCp'};
for i = 1:numel(numericFields)
    fieldName = numericFields{i};
    if isfield(branchIn, fieldName)
        branchOut.(fieldName) = interpolateNumericField(branchIn, fieldName, frequencyIn, requestedFrequency, true);
    end
end

logicalFields = {'validResidual', 'validReference', 'validSmooth', 'validCp', 'validAttenuation', 'valid'};
for i = 1:numel(logicalFields)
    fieldName = logicalFields{i};
    if isfield(branchIn, fieldName)
        branchOut.(fieldName) = interpolateLogicalField(branchIn.(fieldName), frequencyIn, requestedFrequency);
    end
end

branchOut.firstMissingModalMinimumIndex = nan;
branchOut.firstMissingModalMinimumFrequency = nan;
if isfield(branchIn, 'firstMissingModalMinimumFrequency') && isfinite(branchIn.firstMissingModalMinimumFrequency)
    branchOut.firstMissingModalMinimumFrequency = branchIn.firstMissingModalMinimumFrequency;
    idx = find(requestedFrequency >= branchIn.firstMissingModalMinimumFrequency, 1, 'first');
    if ~isempty(idx)
        branchOut.firstMissingModalMinimumIndex = idx;
    end
end
end

function valuesOut = interpolateNumericField(s, fieldName, frequencyIn, frequencyOut, preserveShape)
valuesIn = s.(fieldName);
inputSize = size(valuesIn);
valuesIn = valuesIn(:);
if isempty(valuesIn) || numel(valuesIn) ~= numel(frequencyIn)
    valuesOut = nan(size(frequencyOut));
    return;
end
valid = isfinite(frequencyIn) & isfinite(real(valuesIn)) & isfinite(imag(valuesIn));
if nnz(valid) < 2
    valuesOut = nan(size(frequencyOut));
    return;
end
if ~isreal(valuesIn)
    realPart = interp1(frequencyIn(valid), real(valuesIn(valid)), frequencyOut, 'linear', nan);
    imagPart = interp1(frequencyIn(valid), imag(valuesIn(valid)), frequencyOut, 'linear', nan);
    valuesOut = realPart + 1i*imagPart;
else
    valuesOut = interp1(frequencyIn(valid), valuesIn(valid), frequencyOut, 'linear', nan);
end
if preserveShape && isrowShape(inputSize)
    valuesOut = valuesOut.';
end
end

function valuesOut = interpolateLogicalField(valuesIn, frequencyIn, frequencyOut)
valuesIn = logical(valuesIn(:));
if isempty(valuesIn) || numel(valuesIn) ~= numel(frequencyIn)
    valuesOut = false(size(frequencyOut));
    return;
end
validNumeric = double(valuesIn);
nearest = interp1(frequencyIn, validNumeric, frequencyOut, 'nearest', 0);
valuesOut = logical(nearest(:));
end

function tf = isrowShape(inputSize)
tf = numel(inputSize) == 2 && inputSize(1) == 1;
end

function branchOptions = applyBranchSpecificOptions(branchName, options)
branchOptions = options;
if ~(isfield(options, 'mrlfeRealKUseModalCpWindow') && options.mrlfeRealKUseModalCpWindow)
    return;
end

switch string(branchName)
    case "S0Like"
        window = getOption(options, 'mrlfeViscoS0ModalCpWindow', [0.70, 1.40]);
    otherwise
        window = getOption(options, 'mrlfeViscoA0ModalCpWindow', [0.35, 2.50]);
end

if isnumeric(window) && numel(window) == 2 && all(isfinite(window)) && all(window > 0) && window(2) > window(1)
    branchOptions.mrlfeRealKModalCpLowerFactor = window(1);
    branchOptions.mrlfeRealKModalCpUpperFactor = window(2);
else
    error('Invalid mRLFE modal Cp window for %s. Expected [lower, upper] with 0 < lower < upper.', branchName);
end
end

function diagnostics = buildMRLFEDiagnostics(mrlfeResults, elapsedSeconds)
diagnostics = struct();
diagnostics.elapsedSeconds = elapsedSeconds;
diagnostics.variant = mrlfeResults.variant;
diagnostics.branchNames = string(fieldnames(mrlfeResults.branches));
diagnostics.usedInternalTrackingGrid = mrlfeResults.tracking.usedInternalGrid;
diagnostics.requestedPointCount = numel(mrlfeResults.tracking.requestedFrequency);
diagnostics.trackingPointCount = numel(mrlfeResults.tracking.trackingFrequency);
diagnostics.summary = struct();

branchNames = fieldnames(mrlfeResults.branches);
for i = 1:numel(branchNames)
    name = branchNames{i};
    branch = mrlfeResults.branches.(name);
    finiteResidual = isfinite(branch.residual);
    if isfield(branch, 'validCp')
        validCp = branch.validCp & isfinite(branch.Cp);
    else
        validCp = branch.valid & isfinite(branch.Cp);
    end
    if isfield(branch, 'validResidual')
        validResidual = branch.validResidual & isfinite(branch.Cp);
    else
        validResidual = validCp;
    end
    if isfield(branch, 'validReference')
        validReference = branch.validReference & isfinite(branch.Cp);
    else
        validReference = validCp;
    end
    if isfield(branch, 'validSmooth')
        validSmooth = branch.validSmooth & isfinite(branch.Cp);
    else
        validSmooth = validCp;
    end
    if isfield(branch, 'validAttenuation')
        validAttenuation = branch.validAttenuation & isfinite(branch.attenuation);
    else
        validAttenuation = branch.valid & isfinite(branch.attenuation);
    end

    item = struct();
    item.validPoints = sum(branch.valid);
    item.validCpPoints = sum(validCp);
    item.validResidualPoints = sum(validResidual);
    item.validReferencePoints = sum(validReference);
    item.validSmoothPoints = sum(validSmooth);
    item.validAttenuationPoints = sum(validAttenuation);
    item.totalPoints = numel(branch.valid);
    item.maxCpJumpRelative = maxRelativeJump(branch.Cp(validCp));
    if any(finiteResidual)
        item.maxResidual = max(branch.residual(finiteResidual));
        item.meanResidual = mean(branch.residual(finiteResidual));
    else
        item.maxResidual = nan;
        item.meanResidual = nan;
    end
    if any(validCp)
        item.minCp = min(branch.Cp(validCp));
        item.maxCp = max(branch.Cp(validCp));
    else
        item.minCp = nan;
        item.maxCp = nan;
    end
    if any(validAttenuation)
        item.minAttenuation = min(branch.attenuation(validAttenuation));
        item.maxAttenuation = max(branch.attenuation(validAttenuation));
    else
        item.minAttenuation = nan;
        item.maxAttenuation = nan;
    end
    diagnostics.summary.(name) = item;
end
end

function value = maxRelativeJump(x)
if numel(x) < 2
    value = 0;
else
    value = max(abs(diff(x)) ./ max(abs(x(1:end-1)), eps));
end
end

function value = getOption(options, fieldName, defaultValue)
if isfield(options, fieldName)
    value = options.(fieldName);
else
    value = defaultValue;
end
end
