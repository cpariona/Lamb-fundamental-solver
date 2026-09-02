function fitResult = rlFitDispersionData(experimental, fitConfig)
%RLFITDISPERSIONDATA Fit Rayleigh-Lamb parameters to dispersion data.
%
% One-parameter fits with finite bounds use fminbnd. Multi-parameter fits use
% fminsearch with objective penalties for bounds. This avoids an Optimization
% Toolbox dependency in the first fitting implementation.

problem = rlBuildFitProblem(experimental, fitConfig);
fitResult = solveDispersionFitProblem(problem);
end
