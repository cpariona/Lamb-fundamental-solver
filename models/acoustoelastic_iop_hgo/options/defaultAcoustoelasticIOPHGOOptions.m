function options = defaultAcoustoelasticIOPHGOOptions(varargin)
%DEFAULTACOUSTOELASTICIOPHGOOPTIONS Default options for the acoustoelastic IOP/HGO solver.
%
% This option set is intentionally separate from the main mRLFE options.
% The current implementation solves the direct alpha-beta-gamma problem only.

options = struct();

% Matrix variant for the suspected typo in Appendix Eq. A17.
%   "paper"     : M54 = s2*(s1^2 + 1)*cosh(s1*k*h)
%   "corrected" : M54 = s2*(s1^2 + 1)*cosh(s2*k*h)
options.M54_variant = "corrected";

% Target branch used by the simple continuation tracker.
% Supported first-stage branches:
%   "A0"     : deepest local minimum in low-velocity band.
%   "A0High" : minimum near the high-frequency surface-wave target.
%   "S0"     : deepest local minimum in high-velocity band.
options.branch = "A0";

% Tracking direction in frequency.
%   "forward"  : low frequency -> high frequency.
%   "backward" : high frequency -> low frequency.
% Backward tracking is useful when low-kh minima are highly degenerate and
% high-frequency minima are better separated.
options.trackingDirection = "forward";

% Tracking method for real-Cp sigma_min solvers.
%   "globalScan"             : scan the full physical Cp window at every frequency.
%   "localContinuation"      : after the first point, minimize around previous Cp.
%   "predictiveContinuation" : score candidates around a linear Cp prediction.
%   "singularVectorTracking" : score candidates using Cp prediction + MAC.
options.trackingMethod = "globalScan";
options.localContinuationWindow = 0.20;
options.localContinuationMinWidth = 0.05;
options.localContinuationFallback = "globalScan";
options.predictiveWindow = 0.18;
options.predictiveMinWidth = 0.05;
options.predictionWeight = 8.0;
options.curvatureWeight = 4.0;
options.macWeight = 12.0;
options.minAcceptableMAC = 0.00;
options.allowPredictiveFallbackNearest = true;

% Complex-C determinant continuation options.
options.complexCInitialImagRatio = -1e-3;
options.complexCImagLimitRatio = 0.50;
options.complexCMinScale = 0.05;
options.complexCMaxIter = 250;
options.complexCMaxFunEvals = 900;
options.complexCTolX = 1e-9;
options.complexCTolFun = 1e-9;
options.complexCDisplay = "off";

% Atlas branch-selection policy.
options.atlasBranchPolicy = "atlasA0";
options.invalidateAtlasFallbackOutput = true;

% Internal atlas tracking grid.
options.useInternalAtlasTrackingGrid = true;
options.atlasInitializationMinFrequency_Hz = 300;
options.atlasInitializationNumFrequencyPoints = 50;

% Branch-selection mode.
options.branchSelectionMode = "band";
options.minDimensionlessFrequency = 0;

% Dimensionless Cp bands y = c/sqrt(alpha/rho).
options.A0Band = [0.02, 0.75];
options.A0HighBand = [0.75, 1.20];
options.S0Band = [1.20, 3.40];
options.A0HighTarget = 0.955;
options.branchStartPreference = "auto";

% Phase-velocity scan range.
options.cMin = 0.15;
options.cMax = [];
options.numCpScanPoints = 1400;
options.maxLocalCandidates = 12;

% Branch-aware physical velocity windows.
options.usePhysicalCpWindow = true;
options.A0CpWindowScale = [0.03, 1.15];
options.A0HighCpWindowScale = [0.60, 1.25];
options.S0CpWindowScale = [0.20, 1.25];

% Continuous refinement of the selected atlas branch. Candidate discovery and
% branch linking remain strictly on the discrete atlas cGrid. Setting
% refineLocalMinima=false disables this final bounded minimization stage.
options.refineLocalMinima = true;
options.selectedBranchRefinementTolLogCp = 1e-6;
options.selectedBranchRefinementMaxFunEvals = 24;
options.selectedBranchRefinementMaxIter = 24;

% Local-search width used by the separate direct-dispersion solver.
options.refineHalfWindowPoints = 2;

% Continuity penalties for choosing among local minima.
options.previousCpWeight = 5.0;
options.firstPointPreferenceWeight = 2.0;
options.useBranchContinuityWindow = true;
options.A0ContinuityWindow = 0.45;
options.A0HighContinuityWindow = 0.25;
options.S0ContinuityWindow = 0.18;
options.maxRelativeCpJump = inf;

% Matrix scaling and validity.
options.normalizeRows = true;
options.maxObjectiveForValid = inf;

% Optional name-value overrides.
if mod(numel(varargin), 2) ~= 0
    error('Options must be supplied as name-value pairs.');
end
for i = 1:2:numel(varargin)
    name = char(varargin{i});
    options.(name) = varargin{i+1};
end

if isfield(options, 'atlasBranchPolicy')
    options.atlasBranchPolicy = aeNormalizeBranchPolicy(options.atlasBranchPolicy);
end
end
