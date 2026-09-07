function params = mrlfeSensitivityParameters()
%MRLFESENSITIVITYPARAMETERS Build the reference parameter set for mRLFE studies.

public = lamb.models.mrlfe.mrlfeDefaultParameters();
params = struct();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = public.mu_Pa;
params.nu = public.nu;
params.thickness = public.thickness_m;
params.fmin = 100;
params.fmax = 16000;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";
end
