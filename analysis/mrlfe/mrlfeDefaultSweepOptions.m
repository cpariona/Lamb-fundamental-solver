function options = mrlfeDefaultSweepOptions(branchName, varargin)
%MRLFEDEFAULTSWEEPOPTIONS Build reference solver options for mRLFE sweeps.
%
% branchName must be "A0Like" or "S0Like". The helper configures the
% corresponding Rayleigh-Lamb seed branch and mRLFE branch flag.

p = inputParser;
addRequired(p, 'branchName', @(x)ischar(x) || isstring(x));
addParameter(p, 'EtaS', 0.05, @(x)isnumeric(x) && isscalar(x) && isfinite(x));
addParameter(p, 'A0Policy', "physicalTail", @(x)ischar(x) || isstring(x));
parse(p, branchName, varargin{:});

branchName = string(p.Results.branchName);

options = rlDefaultOptions("Fast");
options.computeMRLFERealK = true;
options.computeMRLFEElasticRealK = true;
options.computeMRLFEViscoRealK = true;
options.computeMRLFEComplexK = false;
options.mrlfeA0Policy = normalizeA0Policy(p.Results.A0Policy);
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;
options.mrlfeParams.etaS = p.Results.EtaS;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;

switch branchName
    case "A0Like"
        options.computeA0 = true;
        options.computeS0 = false;
        options.mrlfeComputeA0Like = true;
        options.mrlfeComputeS0Like = false;
    case "S0Like"
        options.computeA0 = false;
        options.computeS0 = true;
        options.mrlfeComputeA0Like = false;
        options.mrlfeComputeS0Like = true;
    otherwise
        error('Unsupported mRLFE branchName "%s". Use "A0Like" or "S0Like".', branchName);
end

function policy = normalizeA0Policy(policyIn)
policy = string(policyIn);
if policy ~= "physicalTail"
    policy = "physicalTail";
end
end
end
