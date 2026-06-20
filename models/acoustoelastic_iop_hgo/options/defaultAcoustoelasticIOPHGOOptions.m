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
options.localContinuationWindow = 0.20;        % relative half-window around previous Cp
options.localContinuationMinWidth = 0.05;      % absolute minimum half-window [m/s]
options.localContinuationFallback = "globalScan";
options.predictiveWindow = 0.18;               % relative window around predicted Cp
options.predictiveMinWidth = 0.05;             % absolute minimum prediction window [m/s]
options.predictionWeight = 8.0;                % penalty for distance from predicted Cp
options.curvatureWeight = 4.0;                 % penalty for local second difference
options.macWeight = 12.0;                      % penalty for 1-MAC of singular vectors
options.minAcceptableMAC = 0.00;               % 0 disables hard MAC rejection
options.allowPredictiveFallbackNearest = true;

% Complex-C determinant continuation options.
% This is a separate fallback/diagnostic strategy for cases where the real-Cp
% minimum landscape is not smooth. It minimizes abs(det(M)) in c = cr+i*ci.
options.complexCInitialImagRatio = -1e-3;
options.complexCImagLimitRatio = 0.50;
options.complexCMinScale = 0.05;
options.complexCMaxIter = 250;
options.complexCMaxFunEvals = 900;
options.complexCTolX = 1e-9;
options.complexCTolFun = 1e-9;
options.complexCDisplay = "off";

% Atlas branch-selection policy.
%   "atlasA0"              : maintained atlas-based A0 branch policy.
%   "identityA0Diagnostic" : keeps atlasA0 official output and adds a separate
%                            identity-scored candidate branch in result.identityA0.
options.atlasBranchPolicy = "atlasA0";

% Branch-selection mode.
%   "band"   : restrict candidate minima by dimensionless Cp bands.
%   "global" : use all local minima in the Cp grid.
options.branchSelectionMode = "band";

% Minimum dimensionless frequency x = f*h/sqrt(alpha/rho).
% Values below this threshold are skipped by the solver. The default keeps
% all points. Diagnostics can set this to 0.2 to avoid the low-kh region
% where many near-degenerate minima appear.
options.minDimensionlessFrequency = 0;

% Dimensionless Cp bands y = c/sqrt(alpha/rho).
options.A0Band = [0.02, 0.75];
options.A0HighBand = [0.75, 1.20];
options.S0Band = [1.20, 3.40];
options.A0HighTarget = 0.955;

% Initial branch preference for the first frequency point.
%   "auto"          : A0 -> lowCp, A0High -> A0HighTarget, S0 -> tensileTarget
%   "lowCp"         : prefer the lowest-velocity local minimum
%   "A0HighTarget"  : prefer y close to A0HighTarget
%   "tensileTarget" : prefer sqrt((2*beta + 2*gamma)/rho)
%   "shearTarget"   : prefer sqrt(alpha/rho)
%   "bestObjective" : prefer the deepest local minimum
options.branchStartPreference = "auto";

% Phase-velocity scan range. If usePhysicalCpWindow is true, branch-aware
% physical windows override cMin/cMax unless params.cGrid is provided.
options.cMin = 0.15;
options.cMax = [];
options.numCpScanPoints = 1400;
options.maxLocalCandidates = 12;

% Branch-aware physical velocity windows.
% A0/A0High are scaled by sqrt(alpha/rho).
% S0 is scaled by sqrt((2*beta + 2*gamma)/rho).
options.usePhysicalCpWindow = true;
options.A0CpWindowScale = [0.03, 1.15];
options.A0HighCpWindowScale = [0.60, 1.25];
options.S0CpWindowScale = [0.20, 1.25];

% Local refinement around minima detected in the coarse Cp scan.
options.refineLocalMinima = true;
options.refineHalfWindowPoints = 2;

% Continuity penalties for choosing among local minima.
% For this first-stage solver, prefer soft continuity over hard branch
% cuts so the root landscape remains visible during diagnostics.
options.previousCpWeight = 5.0;
options.firstPointPreferenceWeight = 2.0;

% Optional candidate prefilter around the previous Cp after branch-band
% filtering. If at least one candidate lies within the relative window, only
% those nearby candidates are scored. If none are nearby, the nearest
% candidate is kept so the diagnostic remains continuous instead of cutting.
options.useBranchContinuityWindow = true;
options.A0ContinuityWindow = 0.45;
options.A0HighContinuityWindow = 0.25;
options.S0ContinuityWindow = 0.18;

% Conservative jump cutoff. Inf disables the cut. The default is disabled
% while the direct alpha-beta-gamma solver is being validated.
options.maxRelativeCpJump = inf;

% If true, each matrix row is normalized before computing singular values.
options.normalizeRows = true;

% Validity threshold on log10(sigma_min). This is deliberately permissive in
% the first-stage implementation because matrix scaling and branch behavior
% still need to be compared against the paper figures.
options.maxObjectiveForValid = inf;

% Optional name-value overrides.
if mod(numel(varargin), 2) ~= 0
    error('Options must be supplied as name-value pairs.');
end
for i = 1:2:numel(varargin)
    name = char(varargin{i});
    options.(name) = varargin{i+1};
end

% Normalize branch-policy names after overrides so maintained workflows report
% the canonical "atlasA0" spelling and diagnostic policy names consistently.
if isfield(options, 'atlasBranchPolicy')
    options.atlasBranchPolicy = aeNormalizeBranchPolicy(options.atlasBranchPolicy);
end
end
