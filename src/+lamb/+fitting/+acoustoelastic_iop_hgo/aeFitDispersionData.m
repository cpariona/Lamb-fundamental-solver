function fitResult = aeFitDispersionData(experimental, fitConfig)
%AEFITDISPERSIONDATA Fit AE IOP/HGO atlasA0 parameters to dispersion data.
%
% One-parameter fits with finite bounds use fminbnd. Multi-parameter fits use
% fminsearch with objective penalties for bounds. Diagnostic branches are not
% used for fitting.

problem = lamb.fitting.acoustoelastic_iop_hgo.aeBuildFitProblem(experimental, fitConfig);
fitResult = lamb.fitting.solveDispersionFitProblem(problem);
end
