function params = mrlfeDefaultWorkflowParams()
%MRLFEDEFAULTWORKFLOWPARAMS Build user-facing workflow defaults for mRLFE.
%
% These fields match the shared GUI/sweep parameter surface. Translation to
% the canonical mRLFE request remains owned by lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest.

public = lamb.models.mrlfe.mrlfeDefaultParameters();
params = struct();
params.modelType = "ShearPoisson";
params.rho = public.rho_kgm3;
params.mu = public.mu_Pa;
params.nu = public.nu;
params.thickness = public.thickness_m;
params.fmin = 100;
params.fmax = 16000;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";
end
