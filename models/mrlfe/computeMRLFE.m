function mrlfeResults = computeMRLFE(frequency, material, geometry, rlModes, mrlfeParams, options)
% Compute real-k elastic mRLFE fundamental-like branches.
%
% This prototype uses Rayleigh-Lamb A0/S0 branches as seeds and tracks the
% corresponding mRLFE minima of sigma_min(M)/sigma_max(M) in real k.

if nargin < 6
    options = struct();
end

timerStart = tic;

mrlfeResults = struct();
mrlfeResults.modelName = "mRLFE";
mrlfeResults.description = "Real-k elastic modified Rayleigh-Lamb fluid-loaded prototype.";
mrlfeResults.parameters = mrlfeParams;
mrlfeResults.branches = struct();

if isfield(rlModes, 'A0')
    mrlfeResults.branches.A0Like = solveMRLFEBranch("A0Like", rlModes.A0, material, geometry, mrlfeParams, options);
end

if isfield(rlModes, 'S0')
    mrlfeResults.branches.S0Like = solveMRLFEBranch("S0Like", rlModes.S0, material, geometry, mrlfeParams, options);
end

mrlfeResults.diagnostics = buildMRLFEDiagnostics(mrlfeResults, toc(timerStart));
end

function diagnostics = buildMRLFEDiagnostics(mrlfeResults, elapsedSeconds)
diagnostics = struct();
diagnostics.elapsedSeconds = elapsedSeconds;
diagnostics.branchNames = string(fieldnames(mrlfeResults.branches));
diagnostics.summary = struct();

branchNames = fieldnames(mrlfeResults.branches);
for i = 1:numel(branchNames)
    name = branchNames{i};
    branch = mrlfeResults.branches.(name);
    finiteResidual = isfinite(branch.residual);
    validCp = branch.valid & isfinite(branch.Cp);

    item = struct();
    item.validPoints = sum(branch.valid);
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
    diagnostics.summary.(name) = item;
end
end
