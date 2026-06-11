function options = defaultLi2024AcoustoelasticOptions(varargin)
%DEFAULTLI2024ACOUSTOELASTICOPTIONS Default options for Li 2024 acoustoelastic solver.
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

% Branch-selection mode.
%   "band"   : restrict candidate minima by dimensionless Cp bands.
%   "global" : use all local minima in the Cp grid.
options.branchSelectionMode = "band";

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
options.maxLocalCandidates = 8;

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
% For this first-stage Li solver, prefer soft continuity over hard branch
% cuts so the root landscape remains visible during diagnostics.
options.previousCpWeight = 5.0;
options.firstPointPreferenceWeight = 2.0;

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
end
