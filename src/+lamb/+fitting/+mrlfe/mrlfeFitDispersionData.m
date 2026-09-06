function fitResult = mrlfeFitDispersionData(experimental, fitConfig)
%MRLFEFITDISPERSIONDATA Fit mRLFE parameters to dispersion data.
%
% One-parameter fits with finite bounds use fminbnd. Multi-parameter fits use
% fminsearch with objective penalties for bounds. This keeps the first mRLFE
% fitting implementation free of Optimization Toolbox dependency.

problem = lamb.fitting.mrlfe.mrlfeBuildFitProblem(experimental, fitConfig);
fitResult = lamb.fitting.solveDispersionFitProblem(problem);
end
