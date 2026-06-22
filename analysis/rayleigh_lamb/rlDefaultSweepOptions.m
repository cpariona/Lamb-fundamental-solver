function options = rlDefaultSweepOptions()
%RLDEFAULTSWEEPOPTIONS Build reference solver options for Rayleigh-Lamb sweeps.

options = rlDefaultOptions("Balanced");
options.computeA0 = true;
options.computeS0 = true;
options.computeMRLFE = false;
end
