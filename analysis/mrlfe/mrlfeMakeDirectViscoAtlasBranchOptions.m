function options = mrlfeMakeDirectViscoAtlasBranchOptions(options, branchName, policyOptions)
%MRLFEMAKEDIRECTVISCOATLASBRANCHOPTIONS Apply branch-specific direct-visco atlas policy.
%
% This is a diagnostic policy adapter. It maps explicit A0/S0 policy fields to
% the canonical fields currently consumed by solveMRLFEViscoBranchAtlas without
% changing the maintained solver route or the solver core.
%
% Branch-specific fields:
%   mrlfeViscoA0StopAtFirstMissingModalMinimum
%   mrlfeViscoS0StopAtFirstMissingModalMinimum
%   mrlfeViscoA0PreviousCpMaxRelativeJump
%   mrlfeViscoS0PreviousCpMaxRelativeJump
%   mrlfeViscoA0ModalCpWindow
%   mrlfeViscoS0ModalCpWindow
%   mrlfeViscoA0ResidualTolerance
%   mrlfeViscoS0ResidualTolerance

if nargin < 1 || isempty(options)
    options = struct();
end
if nargin < 2 || isempty(branchName)
    branchName = "A0Like";
end
if nargin < 3 || isempty(policyOptions)
    policyOptions = struct();
end

branchName = string(branchName);

% Shared scan/DP knobs. These remain canonical because the underlying DP helper
% still uses the mrlfeA0DP* option names for both branches.
options.mrlfeA0DPCandidates = getOption(policyOptions, 'mrlfeA0DPCandidates', getOption(options, 'mrlfeA0DPCandidates', 8));
options.mrlfeA0DPCpScanPoints = getOption(policyOptions, 'mrlfeViscoAtlasCpScanPoints', getOption(options, 'mrlfeA0DPCpScanPoints', 900));
options.mrlfeA0DPEdgeGuardPoints = getOption(policyOptions, 'mrlfeA0DPEdgeGuardPoints', getOption(options, 'mrlfeA0DPEdgeGuardPoints', 6));
options.mrlfeA0DPRefineCandidates = getOption(policyOptions, 'mrlfeA0DPRefineCandidates', getOption(options, 'mrlfeA0DPRefineCandidates', true));
options.mrlfeA0DPAllowMissing = getOption(policyOptions, 'mrlfeA0DPAllowMissing', getOption(options, 'mrlfeA0DPAllowMissing', true));

% Shared fallback policy. Branch-specific fields override these below.
defaultStop = getOption(policyOptions, 'mrlfeRealKStopAtFirstMissingModalMinimum', getOption(options, 'mrlfeRealKStopAtFirstMissingModalMinimum', true));
defaultJump = getOption(policyOptions, 'mrlfeViscoPreviousCpMaxRelativeJump', getOption(options, 'mrlfeViscoPreviousCpMaxRelativeJump', 0.18));
defaultTolerance = getOption(policyOptions, 'mrlfeResidualTolerance', getOption(options, 'mrlfeResidualTolerance', 1e-3));

if branchName == "S0Like"
    options.mrlfeViscoS0ModalCpWindow = getOption(policyOptions, 'mrlfeViscoS0ModalCpWindow', getOption(options, 'mrlfeViscoS0ModalCpWindow', [0.70, 1.40]));
    options.mrlfeRealKStopAtFirstMissingModalMinimum = getOption(policyOptions, 'mrlfeViscoS0StopAtFirstMissingModalMinimum', defaultStop);
    options.mrlfeViscoPreviousCpMaxRelativeJump = getOption(policyOptions, 'mrlfeViscoS0PreviousCpMaxRelativeJump', defaultJump);
    options.mrlfeResidualTolerance = getOption(policyOptions, 'mrlfeViscoS0ResidualTolerance', defaultTolerance);
    options.mrlfeDirectViscoAtlasBranchPolicy = "S0";
else
    options.mrlfeViscoA0ModalCpWindow = getOption(policyOptions, 'mrlfeViscoA0ModalCpWindow', getOption(options, 'mrlfeViscoA0ModalCpWindow', [0.35, 2.50]));
    options.mrlfeRealKStopAtFirstMissingModalMinimum = getOption(policyOptions, 'mrlfeViscoA0StopAtFirstMissingModalMinimum', defaultStop);
    options.mrlfeViscoPreviousCpMaxRelativeJump = getOption(policyOptions, 'mrlfeViscoA0PreviousCpMaxRelativeJump', defaultJump);
    options.mrlfeResidualTolerance = getOption(policyOptions, 'mrlfeViscoA0ResidualTolerance', defaultTolerance);
    options.mrlfeDirectViscoAtlasBranchPolicy = "A0";
end
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
