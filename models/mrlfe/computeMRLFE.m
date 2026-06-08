function mrlfeResults = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, options)
% Compute mRLFE fundamental-like branches.
%
% The model can use either Rayleigh-Lamb A0/S0 branches or previously
% computed mRLFE A0Like/S0Like branches as seeds. Branch computation can be
% restricted with options.mrlfeComputeA0Like and options.mrlfeComputeS0Like.

if nargin < 6
    options = struct();
end

timerStart = tic;
solveComplexK = isfield(mrlfeParams, 'solveComplexK') && mrlfeParams.solveComplexK;
computeA0Like = getOption(options, 'mrlfeComputeA0Like', true);
computeS0Like = getOption(options, 'mrlfeComputeS0Like', true);

mrlfeResults = struct();
mrlfeResults.modelName = "mRLFE";
if solveComplexK
    mrlfeResults.variant = "complex-k";
    mrlfeResults.description = "Complex-k modified Rayleigh-Lamb fluid-loaded prototype.";
else
    mrlfeResults.variant = "real-k";
    mrlfeResults.description = "Real-k modified Rayleigh-Lamb fluid-loaded prototype.";
end
mrlfeResults.parameters = mrlfeParams;
mrlfeResults.requestedBranches = struct('A0Like', logical(computeA0Like), 'S0Like', logical(computeS0Like));
mrlfeResults.branches = struct();

useA0DP = isfield(options, 'mrlfeA0UseDPTracker') && options.mrlfeA0UseDPTracker && ~solveComplexK;

if computeA0Like
    seedA0 = getSeedMode(seedModes, "A0");
    if ~isempty(seedA0)
        branchOptions = applyBranchSpecificOptions("A0Like", options);
        if useA0DP
            % First compute the local/modal real-k branch.  The DP solver uses it
            % only as an auxiliary candidate-scan guide, not as the final answer.
            % This reproduces the successful prototype behavior where the scan
            % range was built from both the Rayleigh-Lamb seed and the preliminary
            % tracked branch.
            preliminaryA0 = solveMRLFEBranch("A0Like", seedA0, material, geometry, mrlfeParams, branchOptions);
            mrlfeResults.branches.A0Like = solveMRLFEBranchDP("A0Like", seedA0, material, geometry, mrlfeParams, branchOptions, preliminaryA0);
            mrlfeResults.branches.A0Like.preliminaryBranch = preliminaryA0;
        else
            mrlfeResults.branches.A0Like = solveMRLFEBranch("A0Like", seedA0, material, geometry, mrlfeParams, branchOptions);
        end
    end
end

if computeS0Like
    seedS0 = getSeedMode(seedModes, "S0");
    if ~isempty(seedS0)
        branchOptions = applyBranchSpecificOptions("S0Like", options);
        mrlfeResults.branches.S0Like = solveMRLFEBranch("S0Like", seedS0, material, geometry, mrlfeParams, branchOptions);
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

function branchOptions = applyBranchSpecificOptions(branchName, options)
branchOptions = options;
if ~(isfield(options, 'mrlfeRealKUseModalCpWindow') && options.mrlfeRealKUseModalCpWindow)
    return;
end

switch string(branchName)
    case "S0Like"
        window = getOption(options, 'mrlfeHanS0ModalCpWindow', [0.70, 1.40]);
    otherwise
        window = getOption(options, 'mrlfeHanA0ModalCpWindow', [0.35, 2.50]);
end

if isnumeric(window) && numel(window) == 2 && all(isfinite(window)) && all(window > 0) && window(2) > window(1)
    branchOptions.mrlfeRealKModalCpLowerFactor = window(1);
    branchOptions.mrlfeRealKModalCpUpperFactor = window(2);
else
    error('Invalid Han modal Cp window for %s. Expected [lower, upper] with 0 < lower < upper.', branchName);
end
end

function diagnostics = buildMRLFEDiagnostics(mrlfeResults, elapsedSeconds)
diagnostics = struct();
diagnostics.elapsedSeconds = elapsedSeconds;
diagnostics.variant = mrlfeResults.variant;
diagnostics.branchNames = string(fieldnames(mrlfeResults.branches));
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
