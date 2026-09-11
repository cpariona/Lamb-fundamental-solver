function fitResult = rlFitDispersionData(experimental, fitConfig)
%RLFITDISPERSIONDATA Fit Rayleigh-Lamb parameters to dispersion data.
%
% EXPERIMENTAL requires frequency_Hz and Cp_mps column-compatible data;
% validMask and standardError_Cp_mps are optional. validMask defines the fixed
% objective observations and every selected point requires a finite model Cp.
% FITCONFIG supplies the branch, fixed/free parameters, initial guess, bounds,
% solver options, and optimizer controls. The evaluator tracks one coherent A0
% or S0 branch on a continuation grid containing every experimental frequency
% and disables prediction fallback.
%
% One-parameter fits with finite bounds use fminbnd. Multi-parameter fits use
% fminsearch with objective penalties for bounds. This avoids an Optimization
% Toolbox dependency. The result contains fitted/fixed parameters, observed
% and fitted curves, masks, residuals, metrics, identifiability, optimizer
% evidence, and the final model evaluation.

problem = lamb.fitting.rayleigh_lamb.rlBuildFitProblem(experimental, fitConfig);
fitResult = lamb.fitting.solveDispersionFitProblem(problem);
end
