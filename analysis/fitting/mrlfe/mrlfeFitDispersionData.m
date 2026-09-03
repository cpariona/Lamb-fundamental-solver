function fitResult = mrlfeFitDispersionData(experimental, fitConfig)
%MRLFEFITDISPERSIONDATA Fit mRLFE parameters to dispersion data.
%
% One-parameter fits with finite bounds use fminbnd. Multi-parameter fits use
% fminsearch with objective penalties for bounds. This keeps the first mRLFE
% fitting implementation free of Optimization Toolbox dependency.

problem = mrlfeBuildFitProblem(experimental, fitConfig);
fitResult = solveDispersionFitProblem(problem);
end
