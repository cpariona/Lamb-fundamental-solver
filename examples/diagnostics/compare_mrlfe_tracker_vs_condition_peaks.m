% Compare mRLFE tracker with brute-force residual/condition peaks.
% Diagnostic only: this script does not change solver internals.

startup();

branchName = "A0Like";              % "A0Like" or "S0Like"
modelName  = "mRLFEElasticRealK";   % "mRLFEElasticRealK" or "mRLFEHanViscoRealK"

params = defaultParams();
params.E = 100e3;
params.nu = 0.4999;
params.CL = 1500;
params.rho = 1050;
params.thickness = 0.5e-3;
params.fmin = 500;
params.fmax = 16000;
params.numFrequencyPoints = 120;
params.frequencySpacing = "hybrid";

options = defaultOptions("Balanced");
options