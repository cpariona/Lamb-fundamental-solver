function options = rlDefaultSweepOptions(branchName)
%RLDEFAULTSWEEPOPTIONS Build reference solver options for Rayleigh-Lamb sweeps.

if nargin < 1 || strlength(string(branchName)) == 0
    branchName = "A0";
end
branchName = string(branchName);

options = lamb.models.rayleigh_lamb.rlDefaultOptions("Balanced");

switch branchName
    case "A0"
        options.computeA0 = true;
        options.computeS0 = false;
    case "S0"
        options.computeA0 = false;
        options.computeS0 = true;
    otherwise
        error('Unsupported Rayleigh-Lamb branchName "%s". Use "A0" or "S0".', char(branchName));
end
end
