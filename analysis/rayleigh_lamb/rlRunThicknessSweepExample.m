function [sweepResults, a0Summary, s0Summary] = rlRunThicknessSweepExample(varargin)
%RLRUNTHICKNESSSWEEPEXAMPLE Run the maintained Rayleigh-Lamb thickness sweep.
%
% This helper keeps the public example short while reusing the generic
% parametric sweep and plotting utilities.

p = inputParser;
addParameter(p, 'AssignToBase', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'NewFigure', true, @(x)islogical(x) || isnumeric(x));
parse(p, varargin{:});

params = rlDefaultParams();
options = rlDefaultOptions("Balanced");
options.computeA0 = true;
options.computeS0 = true;

sweepSpec = struct();
sweepSpec.parameter = "thickness";
sweepSpec.values = [0.1 0.2 0.3 0.4 0.5] * 1e-3;
sweepSpec.label = "thickness";
sweepSpec.units = "mm";
sweepSpec.displayScale = 1e-3;

sweepResults = runParametricSweep(params, options, sweepSpec);

plotParametricSweepCp(sweepResults, "RayleighLamb", "A0", ...
    'Title', "Rayleigh-Lamb A0 thickness sweep", ...
    'NewFigure', logical(p.Results.NewFigure));

plotParametricSweepCp(sweepResults, "RayleighLamb", "S0", ...
    'Title', "Rayleigh-Lamb S0 thickness sweep", ...
    'NewFigure', true);

a0Summary = summarizeParametricSweepBranch(sweepResults, "RayleighLamb", "A0");
s0Summary = summarizeParametricSweepBranch(sweepResults, "RayleighLamb", "S0");

if logical(p.Results.AssignToBase)
    assignin('base', 'RayleighLambThicknessSweepResults', sweepResults);
    assignin('base', 'RayleighLambThicknessSweepA0Summary', a0Summary);
    assignin('base', 'RayleighLambThicknessSweepS0Summary', s0Summary);
end
end
