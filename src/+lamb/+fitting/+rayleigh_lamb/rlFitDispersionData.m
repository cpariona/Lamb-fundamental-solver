function fitResult = rlFitDispersionData(experimental, fitConfig)
%RLFITDISPERSIONDATA Fit Rayleigh-Lamb parameters to dispersion data.
%
% EXPERIMENTAL requires frequency_Hz and Cp_mps column-compatible data;
% validMask and standardError_Cp_mps are optional. validMask defines the fixed
% objective observations and every selected point requires positive finite Hz,
% positive finite Cp and a finite model prediction. Invalid selected data are
% rejected, never silently removed by normalization.
% FITCONFIG supplies the branch, fixed/free parameters, initial guess, bounds,
% solver options, and optimizer controls. The evaluator tracks one coherent A0
% or S0 branch through the canonical public solver and disables prediction
% fallback. Nonpositive/nonfinite frequencies require explicit validMask=false.
% They remain in the result, with NaN predictions and false model validity.
% Positive finite frequencies, including excluded ones, retain direct evaluation.
% Observation-aligned modelEvaluation arrays retain the original length/order;
% evaluatedObservationMask identifies evaluated rows when exclusions require
% reconstruction. modelResult and diagnostics retain the official solver grid.
% reliability counts full-axis prediction availability, not objective coverage;
% residualInfo reports complete coverage of the fixed fitting mask separately.
%
% One-parameter fits with finite bounds use fminbnd. Multi-parameter fits use
% fminsearch with objective penalties for bounds. This avoids an Optimization
% Toolbox dependency. The result contains fitted/fixed parameters, observed
% and fitted curves, masks, residuals, metrics, identifiability, optimizer
% evidence, and the final model evaluation.

problem = lamb.fitting.rayleigh_lamb.rlBuildFitProblem(experimental, fitConfig);
fitResult = lamb.fitting.solveDispersionFitProblem(problem);
end
