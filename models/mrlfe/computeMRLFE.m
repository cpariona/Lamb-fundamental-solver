function mrlfeResults = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, options)
% Compute mRLFE fundamental-like branches.
%
% The model can use either Rayleigh-Lamb A0/S0 branches or previously
% computed mRLFE A0Like/S0Like branches as seeds.

if nargin < 6
    options = struct();
end

timerStart = tic;
solveComplexK = isfield(mrlfeParams, 'solveComplexK') && mrlfeParams.solveComplexK;

mrlfeResults = struct();
mrlfeResults.modelName = "mRLFE";
if solveComplexK
    mrlfeResults.variant = "complex-k";
    mrlfeResults.description = "Complex-k modified Rayleigh-Lamb fluid-loaded prototype.";
else
    mrlfeResults.variant = "real-k";
    mrlfeResults.description = "Real-k elastic modified Rayleigh-Lamb fluid-loaded prototype.";
end
mrlfeResults.parameters = mrlfeParams;
mrlfeResults.branches = struct();

seedA0 = getSeedMode(seedModes, "A0");
if ~isempty(seedA0)
    mrlfeResults.branches.A0Like = solveMRLFEBranch("A0Like", seedA0, material, geometry, mrlfeParams, options);
end

seedS0 = getSeedMode(seedModes, "S0");
if ~isempty(seedS0)
    mrlfeResults.branches.S0Like = solveMRLFEBranch("S0Like", seedS0, material, geometry, mrlfeParams, options);
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
    if isfield(branch, 'validAttenuation')
        validAttenuation = branch.validAttenuation & isfinite(branch.attenuation);
    else
        validAttenuation = branch.valid & isfinite(branch.attenuation);
    end

    item = struct();
    item.validPoints = sum(branch.valid);
    item.validCpPoints = sum(validCp);
    item.validAttenuationPoints = sum(validAttenuation);
    item.totalPoints = numel(branch.valid);
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
