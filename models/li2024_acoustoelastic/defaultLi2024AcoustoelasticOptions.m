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
options.branch = "A0";

% Initial branch preference for the first frequency point.
%   "auto"          : A0 -> lowCp, S0 -> tensileTarget
%   "lowCp"         : prefer the lowest-velocity local minimum
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
% A0 is scaled by sqrt(alpha/rho).
% S0 is scaled by sqrt((2*beta + 2*gamma)/rho).
options.usePhysicalCpWindow = true;
options.A0CpWindowScale = [0.03, 1.15];
options.S0CpWindowScale = [0.20, 1.25];

% Local refinement around minima detected in the coarse Cp scan.
options.refineLocalMinima = true;
options.refineHalfWindowPoints = 2;

% Light continuity penalties for choosing among local minima.
options.previousCpWeight = 1.0;
options.firstPointPreferenceWeight = 2.0;

% Conservative jump cutoff. Inf disables the cut. Default remains moderately
% permissive for the first-stage direct matrix solver.
options.maxRelativeCpJump = 0.35;

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
