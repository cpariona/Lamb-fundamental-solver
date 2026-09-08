function fitResult = aeFitDispersionData(experimental, fitConfig)
%AEFITDISPERSIONDATA Fit AE IOP/HGO atlasA0 parameters to dispersion data.
%
% EXPERIMENTAL requires frequency_Hz and Cp_mps; validMask and
% standardError_Cp_mps are optional. FITCONFIG supplies fixed/free physical
% parameters, initial guesses, bounds, solver options, and optimizer
% controls. The evaluator always uses the official atlasA0 output from
% lamb.models.acoustoelastic_iop_hgo.aeSolveBranch.
%
% One-parameter fits with finite bounds use fminbnd. Multi-parameter fits use
% fminsearch with objective penalties for bounds. Diagnostic branches are not
% used for fitting. The result reports fitted and fixed parameters, curves,
% masks, metrics, optimizer evidence, and the final model evaluation.

problem = lamb.fitting.acoustoelastic_iop_hgo.aeBuildFitProblem(experimental, fitConfig);
fitResult = lamb.fitting.solveDispersionFitProblem(problem);
end
