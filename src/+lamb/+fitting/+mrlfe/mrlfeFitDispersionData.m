function fitResult = mrlfeFitDispersionData(experimental, fitConfig)
%MRLFEFITDISPERSIONDATA Fit mRLFE parameters to dispersion data.
%
% EXPERIMENTAL requires frequency_Hz and Cp_mps; validMask and
% standardError_Cp_mps are optional. validMask defines the fixed objective
% observations and every selected point requires a finite model Cp. FITCONFIG
% owns branch, fixed/free parameters, initial guess, bounds, solver options,
% and optimizer controls. Every physical evaluation routes through
% lamb.models.mrlfe.mrlfeSolve. Objective evaluation may use the bounded
% fitOptimized continuation grid; explicit requested-curve evaluation uses the
% selected numerical preset.
%
% One-parameter fits with finite bounds use fminbnd. Multi-parameter fits use
% fminsearch with objective penalties for bounds. This keeps the first mRLFE
% fitting implementation free of Optimization Toolbox dependency. The result
% includes the final public model evaluation and objective-consistent curve.

problem = lamb.fitting.mrlfe.mrlfeBuildFitProblem(experimental, fitConfig);
fitResult = lamb.fitting.solveDispersionFitProblem(problem);
end
