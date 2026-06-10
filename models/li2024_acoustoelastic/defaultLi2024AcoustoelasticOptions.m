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

% Phase-velocity scan range. If cMax is empty, the solver estimates a
% conservative upper bound from alpha, beta, gamma, and rho.
options.cMin = 0.15;
options.cMax = [];
options.numCpScanPoints = 1400;
options.maxLocalCandidates = 8;

% Local refinement around minima detected in the coarse Cp scan.
options.refineLocalMinima = true;
options.refineHalfWindowPoints = 2;

% Continuity penalties for choosing among local minima.
options.previousCpWeight = 0.35;
options.firstPointPreferenceWeight = 0.15;

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
