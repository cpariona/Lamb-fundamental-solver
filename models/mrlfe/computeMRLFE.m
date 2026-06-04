function mrlfeResults = computeMRLFE(frequency, material, geometry, rlModes, mrlfeParams, options)
% Compute real-k elastic mRLFE fundamental-like branches.
%
% This prototype uses Rayleigh-Lamb A0/S0 branches as seeds and tracks the
% corresponding mRLFE minima of sigma_min(M)/sigma_max(M) in real k.

if nargin < 6
    options = struct();
end

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
end
